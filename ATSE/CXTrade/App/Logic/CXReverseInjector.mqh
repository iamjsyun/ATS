#ifndef CXREVERSEINJECTOR_MQH
#define CXREVERSEINJECTOR_MQH

#include "..\..\Platform\Core\Interfaces\ICXContext.mqh"
#include "..\..\Platform\Core\Interfaces\ICXParam.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Interfaces\IDatabase.mqh"
#include "..\..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Platform\Core\Interfaces\ICXTradingSession.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Models\CXTerminalAsset.mqh"
#include "..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "CXTerminalScanner.mqh"
#include <Object.mqh>

/**
 * @class CXReverseInjector
 * @brief 터미널의 실물 자산을 기반으로 세션을 역으로 복구/생성 담당
 */
class CXReverseInjector : public CObject {
private:
    CXTerminalScanner*      m_scanner;
    IRepository*            m_repo;
    ICXSessionManager*      m_manager;
    ICXConfig*              m_config; // [v16.2] Explicit dependency
    IDatabase*              m_db;     // SQLite database handle

public:
    CXReverseInjector(CXTerminalScanner* scanner, IRepository* repo, ICXSessionManager* manager, ICXConfig* config, IDatabase* db) 
        : m_scanner(scanner), m_repo(repo), m_manager(manager), m_config(config), m_db(db) {}

    /**
     * @brief [v11.3 / GEMINI.md] Apply options from SQLite database `channel_options` table
     */
    void ApplyChannelOptions(CXSignal* sig, int cno, int dir, bool isOrder) {
        if(CheckPointer(m_db) == POINTER_INVALID || CheckPointer(sig) == POINTER_INVALID) return;

        string sql = StringFormat("SELECT buy_entry_offset, sell_entry_offset, tp_points, sl_points, ts_trigger, ts_step, ikte_start, ikte_step FROM channel_options WHERE cno=%d", cno);
        int handle = m_db.GetHandle();
        int req = DatabasePrepare(handle, sql);
        
        bool found = false;
        double buy_entry_offset = 0;
        double sell_entry_offset = 0;
        double tp_points = 0;
        double sl_points = 0;
        int ts_trigger = 0;
        int ts_step = 0;
        double ikte_start = 0;
        double ikte_step = 0;

        if(req != INVALID_HANDLE) {
            if(DatabaseRead(req)) {
                found = true;
                DatabaseColumnDouble(req, 0, buy_entry_offset);
                DatabaseColumnDouble(req, 1, sell_entry_offset);
                DatabaseColumnDouble(req, 2, tp_points);
                DatabaseColumnDouble(req, 3, sl_points);
                DatabaseColumnInteger(req, 4, ts_trigger);
                DatabaseColumnInteger(req, 5, ts_step);
                DatabaseColumnDouble(req, 6, ikte_start);
                DatabaseColumnDouble(req, 7, ikte_step);
            }
            DatabaseFinalize(req);
        } else {
            PrintFormat("[REVERSE-INJECTOR] Failed to prepare SQL for channel %d", cno);
        }

        if(found) {
            sig.SetCno(cno);
            sig.SetDir(dir);
            if(isOrder) {
                // Pending order rules: apply both entry and exit options
                double offset = (dir == CX_DIR_BUY) ? buy_entry_offset : sell_entry_offset;
                sig.SetTEStart(offset);
                sig.SetTEStep(100.0);
                sig.SetTELimit(1000.0);
                sig.SetTEInterval(1);
                
                sig.SetIkTeStart(0.0);
                sig.SetIkTeStep(0.0);
            } else {
                // Active position rules: disable TE (entry), apply exit options only
                sig.SetTEStart(0.0);
                sig.SetTEStep(0.0);
                sig.SetTELimit(0.0);
                sig.SetTEInterval(0);
                
                sig.SetIkTeStart(ikte_start);
                sig.SetIkTeStep(ikte_step);
            }
            
            sig.SetTP(tp_points);
            sig.SetSL(sl_points);
            sig.SetTSStart(ts_trigger);
            sig.SetTSStep(ts_step);
        } else {
            PrintFormat("[REVERSE-INJECTOR] Channel options for cno=%d not found in DB. Keeping defaults.", cno);
        }
    }

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
                int dir = (asset.type == (int)ORDER_TYPE_BUY || asset.type == (int)ORDER_TYPE_BUY_LIMIT || asset.type == (int)ORDER_TYPE_BUY_STOP) ? CX_DIR_BUY : CX_DIR_SELL;
                fakeSig.SetDir(dir);
                fakeSig.SetType((ENUM_CX_ORDER_TYPE)asset.type);
                
                bool isOrder = true;
                // [v16.12 Asset Info Synchronization (Positions vs Orders)]
                if(PositionSelectByTicket(asset.ticket)) {
                    fakeSig.SetPriceOpen(PositionGetDouble(POSITION_PRICE_OPEN));
                    fakeSig.SetSL(PositionGetDouble(POSITION_SL));
                    fakeSig.SetTP(PositionGetDouble(POSITION_TP));
                    isOrder = false;
                } else if(OrderSelect(asset.ticket)) {
                    fakeSig.UpdatePriceSignal(OrderGetDouble(ORDER_PRICE_OPEN));
                    fakeSig.SetSL(OrderGetDouble(ORDER_SL));
                    fakeSig.SetTP(OrderGetDouble(ORDER_TP));
                    isOrder = true;
                }
                
                // Parse CNO from SID (format: CNO(4)-YYMMDDHH(8)-...)
                string parts[];
                int cno = 0;
                if(StringSplit(sid, '-', parts) >= 1) {
                    cno = (int)StringToInteger(parts[0]);
                }
                
                // Apply options from DB
                ApplyChannelOptions(fakeSig, cno, dir, isOrder);
                
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
