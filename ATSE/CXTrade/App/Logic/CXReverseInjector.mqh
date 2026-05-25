#ifndef CXREVERSEINJECTOR_MQH
#define CXREVERSEINJECTOR_MQH

#include "..\..\Core\Interfaces\ICXContext.mqh"
#include "..\..\Core\Interfaces\ICXParam.mqh"
#include "..\..\Core\Interfaces\IRepository.mqh"
#include "..\..\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Core\Interfaces\ICXTradingSession.mqh"
#include "..\..\Core\Models\CXSignal.mqh"
#include "..\..\Core\Models\CXTerminalAsset.mqh"
#include "..\..\Shared\Logging\CXAuditFormatter.mqh"
#include "CXTerminalScanner.mqh"

/**
 * @class CXReverseInjector
 * @brief 터미널의 실물 자산을 기반으로 세션을 역으로 복구/생성 담당
 */
class CXReverseInjector {
private:
    CXTerminalScanner*      m_scanner;
    IRepository*            m_repo;
    ICXSessionManager*      m_manager;
    ICXConfig*              m_config; // [v16.2] Explicit dependency

public:
    CXReverseInjector(CXTerminalScanner* scanner, IRepository* repo, ICXSessionManager* manager, ICXConfig* config) 
        : m_scanner(scanner), m_repo(repo), m_manager(manager), m_config(config) {}

    /**
     * @brief 스캔 및 역주입 실행 (Zombie Recovery)
     */
    void Pulse(ICXParam* xp) {
        if(CheckPointer(m_scanner) == POINTER_INVALID || CheckPointer(m_repo) == POINTER_INVALID || CheckPointer(m_manager) == POINTER_INVALID) return;

        // [v16.2] Use explicitly injected config instead of context lookup
        ICXConfig* config = m_config;
        
        CArrayObj terminalAssets;
        if(m_scanner.ScanAll(GetPointer(terminalAssets)) <= 0) return;

        for(int i = 0; i < terminalAssets.Total(); i++) {
            CXTerminalAsset* asset = CX_CAST(CXTerminalAsset, terminalAssets.At(i));
            if(CheckPointer(asset) == POINTER_INVALID) continue;

            string sid = asset.sid;
            int magic = asset.magic;
            
            // [Tier 1] 매직넘버 격리 원칙 (내 관리 대상이 아니면 무시)
            if(CheckPointer(config) != POINTER_INVALID && !config.IsTargetMagic(magic)) continue;

            // 0. 이미 해당 SID가 세션 풀에서 관리 중인지 확인 (중복 주입 방지)
            ICXTradingSession* existing = m_manager.FindSessionBySid(sid);
            if(CheckPointer(existing) != POINTER_INVALID) continue;

            // 1. DB에서 해당 SID의 신호 정보 조회
            ICXSignal* sig = m_repo.GetSignalBySid(sid);
            
            // [Tier 2] 좀비 판별 (DB에 없거나 이미 종료된 신호인데 터미널에 실물이 있는 경우)
            if(CheckPointer(sig) == POINTER_INVALID || sig.GetStatus() >= XE_CLOSED_SIGNAL) {
                // 가상 신호 생성 (청산 전용)
                CXSignal* fakeSig = new CXSignal();
                fakeSig.SetSid(sid);
                fakeSig.symbol = asset.symbol;
                fakeSig.ticket = asset.ticket;
                fakeSig.magic = asset.magic;
                fakeSig.lot = asset.lot;
                
                // Map broker order type to CX direction
                fakeSig.SetDir((asset.type == (int)ORDER_TYPE_BUY || asset.type == (int)ORDER_TYPE_BUY_LIMIT || asset.type == (int)ORDER_TYPE_BUY_STOP) ? CX_DIR_BUY : CX_DIR_SELL);
                fakeSig.SetType((ENUM_CX_ORDER_TYPE)asset.type);
                
                // [v16.12 Asset Info Synchronization (Positions vs Orders)]
                if(PositionSelectByTicket(asset.ticket)) {
                    fakeSig.SetPriceOpen(PositionGetDouble(POSITION_PRICE_OPEN));
                    fakeSig.SetSL(PositionGetDouble(POSITION_SL));
                    fakeSig.SetTP(PositionGetDouble(POSITION_TP));
                } else if(OrderSelect(asset.ticket)) {
                    fakeSig.UpdatePriceSignal(OrderGetDouble(ORDER_PRICE_OPEN));
                    fakeSig.SetSL(OrderGetDouble(ORDER_SL));
                    fakeSig.SetTP(OrderGetDouble(ORDER_TP));
                }
                
                fakeSig.SetXAEntry(XA_ACTIVE); // 1
                fakeSig.SetXAExit(XA_RAW);     // 0
                fakeSig.SetStatus(XE_QUARANTINED); 
                fakeSig.SetStatusMsg("[ZOMBIE] Orphan Asset Quarantined. User Approval Required.");
                
                ICXSignal* oldSig = xp.GetSignal();
                xp.SetSignal(fakeSig);
                XP_LOG_WARN(xp, CXAuditFormatter::Build("REVERSE-ZOMBIE", xp, StringFormat("Ticket:%I64d. Orphan asset found. Quarantined for safety.", asset.ticket)));
                xp.SetSignal(oldSig);

                // DB에 기록 후 세션 기동
                m_repo.SaveSignal(fakeSig);
                if(CheckPointer(sig) != POINTER_INVALID) delete sig;
                sig = fakeSig;
            }

            // 2. 세션 동적 생성 및 주입 (v15.9)
            CXParam sp;
            sp.SetSignal(sig);
            ICXTradingSession* session = m_manager.CreateSession(GetPointer(sp));
            if(CheckPointer(session) != POINTER_INVALID) {
                ICXSignal* oldSig = xp.GetSignal();
                xp.SetSignal(sig);
                XP_LOG_INFO(xp, CXAuditFormatter::Build("REVERSE-RESTORE", xp));
                xp.SetSignal(oldSig);

                session.InjectState(CX_CAST(CXSignal, sig));
                
                // [v16.4 Scenario C] Jump to ACTIVE state but keep it in Hold (XE_QUARANTINED)
                if(sig.GetStatus() == XE_QUARANTINED) {
                    session.ForceTransition(SESSION_ACTIVE);
                } else if(sig.GetXAExit() == XA_ACTIVE) {
                    session.ForceTransition(SESSION_LIQUIDATING);
                } else if(sig.GetStatus() == XE_EXECUTED) {
                    session.ForceTransition(SESSION_ACTIVE);
                }
            } else {
                ICXSignal* oldSig = xp.GetSignal();
                xp.SetSignal(sig);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("REVERSE-FAIL", xp, "Failed to borrow session"));
                xp.SetSignal(oldSig);

                if(CheckPointer(sig) != POINTER_INVALID) delete sig;
            }
        }
    }
};

#endif
