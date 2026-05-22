#ifndef CXREVERSEINJECTOR_MQH
#define CXREVERSEINJECTOR_MQH

#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\IRepository.mqh"
#include "..\..\Interfaces\ICXTradingSessionPool.mqh"
#include "..\..\Interfaces\ICXTradingSession.mqh"
#include "..\..\Models\CXSignal.mqh"
#include "..\..\Models\CXTerminalAsset.mqh"
#include "CXTerminalScanner.mqh"

/**
 * @class CXReverseInjector
 * @brief 터미널의 실물 자산을 기반으로 세션을 역으로 복구/생성 담당
 */
class CXReverseInjector {
private:
    CXTerminalScanner*      m_scanner;
    IRepository*            m_repo;
    ICXTradingSessionPool*  m_pool;

public:
    CXReverseInjector(CXTerminalScanner* scanner, IRepository* repo, ICXTradingSessionPool* pool) 
        : m_scanner(scanner), m_repo(repo), m_pool(pool) {}

    /**
     * @brief 스캔 및 역주입 실행 (Zombie Recovery)
     */
    void Pulse(ICXParam* xp) {
        if(CheckPointer(m_scanner) == POINTER_INVALID || CheckPointer(m_repo) == POINTER_INVALID || CheckPointer(m_pool) == POINTER_INVALID) return;
        
        // [v11.7] 타겟 매직넘버 정보 획득 (격리 원칙)
        ICXConfig* config = NULL;
        if(CheckPointer(xp) != POINTER_INVALID) config = dynamic_cast<ICXConfig*>(xp.GetContext().Get("config"));
        
        CArrayObj terminalAssets;
        if(m_scanner.ScanAll(GetPointer(terminalAssets)) <= 0) return;

        for(int i = 0; i < terminalAssets.Total(); i++) {
            CXTerminalAsset* asset = dynamic_cast<CXTerminalAsset*>(terminalAssets.At(i));
            if(CheckPointer(asset) == POINTER_INVALID) continue;

            string sid = asset.sid;
            int magic = asset.magic;
            
            // [Tier 1] 매직넘버 격리 원칙 (내 관리 대상이 아니면 무시)
            if(CheckPointer(config) != POINTER_INVALID && !config.IsTargetMagic(magic)) continue;

            // 0. 이미 해당 SID가 세션 풀에서 관리 중인지 확인 (중복 주입 방지)
            ICXTradingSession* existing = m_pool.FindSessionBySid(sid);
            if(CheckPointer(existing) != POINTER_INVALID) continue;

            // 1. DB에서 해당 SID의 신호 정보 조회
            ICXSignal* sig = m_repo.GetSignalBySid(sid);
            
            // [Tier 2] 좀비 판별 (DB에 없거나 이미 종료된 신호인데 터미널에 실물이 있는 경우)
            if(CheckPointer(sig) == POINTER_INVALID || sig.GetStatus() >= XE_CLOSED_SIGNAL) {
                XP_LOG_WARN(xp, StringFormat("[REVERSE-INJECT] ZOMBIE DETECTED: SID:%s Ticket:%I64d. Forced Liquidation start.", sid, asset.ticket));
                
                // 가상 신호 생성 (청산 전용)
                CXSignal* fakeSig = new CXSignal();
                fakeSig.SetSid(sid);
                fakeSig.symbol = asset.symbol;
                fakeSig.ticket = asset.ticket;
                fakeSig.type = (ENUM_CX_ORDER_TYPE)asset.type;
                fakeSig.xa_exit = XA_ACTIVE; // 즉시 청산 의도 주입
                fakeSig.xe_status = XE_EXECUTED; 
                fakeSig.xe_status_msg = "[ZOMBIE] Orphan Asset Recovery";
                
                // DB에 기록 후 세션 기동
                m_repo.SaveSignal(fakeSig);
                if(CheckPointer(sig) != POINTER_INVALID) delete sig;
                sig = fakeSig;
            }

            // 2. 세션 풀에서 세션 빌려와서 주입
            ICXTradingSession* session = m_pool.BorrowSession();
            if(CheckPointer(session) != POINTER_INVALID) {
                XP_LOG_INFO(xp, StringFormat("[REVERSE-INJECT] Restoring session for SID: %s (Status: %d)", sid, sig.GetStatus()));
                session.InjectState(dynamic_cast<CXSignal*>(sig));
            } else {
                XP_LOG_ERROR(xp, StringFormat("[REVERSE-INJECT] Failed to borrow session for recovery of SID: %s", sid));
                if(CheckPointer(sig) != POINTER_INVALID) delete sig;
            }
        }
    }
};

#endif
