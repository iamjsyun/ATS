#ifndef CXSTAGEREVERSEINJECT_MQH
#define CXSTAGEREVERSEINJECT_MQH

#include "..\..\Platform\Core\Interfaces\IXStage.mqh"
#include "..\..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\..\Platform\Core\Interfaces\IDatabase.mqh"
#include "..\..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Platform\Core\Interfaces\ICXTradingSession.mqh"
#include "..\..\Platform\Core\Models\CXSignal.mqh"
#include "..\..\Platform\Core\Models\CXTerminalAsset.mqh"
#include "..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"

#include <Arrays\ArrayObj.mqh>

/**
 * @class CXStageReverseInject
 * @brief 발견된 좀비 자산에 대해 가상 신호를 주입하고 세션을 강제로 복구/기동하는 단계
 */
class CXStageReverseInject : public IXStage {
public:
    CXStageReverseInject() {}
    virtual ~CXStageReverseInject() {}

    virtual string Name() override { return "Stage_ReverseInject"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CArrayObj* zombies = CX_GET_OBJ(ctx, "zombie_assets", CArrayObj);
        return (IS_VALID(zombies) && zombies.Total() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CArrayObj* zombies = CX_GET_OBJ(ctx, "zombie_assets", CArrayObj);
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        IDatabase* db = CX_GET_OBJ(ctx, "db", IDatabase);
        ICXSessionManager* session_mgr = CX_GET_OBJ(ctx, "session_mgr", ICXSessionManager);

        if(IS_INVALID(zombies) || IS_INVALID(repo) || IS_INVALID(session_mgr)) {
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
            return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_ENTRY_DISCOVERY") : STATE_UNCHANGED;
        }

        int total = zombies.Total();
        for(int i = 0; i < total; i++) {
            CXTerminalAsset* asset = CX_CAST(CXTerminalAsset, zombies.At(i));
            if(IS_INVALID(asset)) continue;

            string sid = asset.sid;

            // 가상 신호 생성 (청산 전용)
            CXSignal* fakeSig = new CXSignal();
            fakeSig.SetSid(sid);
            fakeSig.symbol = asset.symbol;
            fakeSig.ticket = asset.ticket;
            fakeSig.magic = asset.magic;
            fakeSig.lot = asset.lot;

            // 브로커 포지션/주문 타입 매핑
            int dir = (asset.type == (int)ORDER_TYPE_BUY || asset.type == (int)ORDER_TYPE_BUY_LIMIT || asset.type == (int)ORDER_TYPE_BUY_STOP) ? CX_DIR_BUY : CX_DIR_SELL;
            fakeSig.SetDir(dir);
            fakeSig.SetType((ENUM_CX_ORDER_TYPE)asset.type);

            bool isOrder = true;
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

            // Parse CNO from SID
            string parts[];
            int cno = 0;
            if(StringSplit(sid, '-', parts) >= 1) {
                cno = (int)StringToInteger(parts[0]);
            }

            // Apply options from DB
            ApplyChannelOptions(db, fakeSig, cno, dir, isOrder);

            fakeSig.SetXAEntry(XA_ACTIVE); // 1
            fakeSig.SetXAExit(XA_RAW);     // 0
            fakeSig.SetStatus(XE_QUARANTINED);
            fakeSig.SetStatusMsg("[ZOMBIE] Orphan Asset Quarantined. User Approval Required.");

            ICXSignal* oldSig = xp.GetSignal();
            xp.SetSignal(fakeSig);
            XP_LOG_WARN(xp, CXAuditFormatter::Build("REVERSE-ZOMBIE", xp, StringFormat("Ticket:%I64u. Orphan asset found. Quarantined for safety.", asset.ticket)));
            xp.SetSignal(oldSig);

            // DB에 저장
            repo.SaveSignal(fakeSig);

            // 세션 기동 및 주입
            CXParam sp;
            sp.SetSignal(fakeSig);
            ICXTradingSession* session = session_mgr.CreateSession(GetPointer(sp));
            if(IS_VALID(session)) {
                ICXSignal* prevSig = xp.GetSignal();
                xp.SetSignal(fakeSig);
                XP_LOG_INFO(xp, CXAuditFormatter::Build("REVERSE-RESTORE", xp));
                xp.SetSignal(prevSig);

                session.InjectState(fakeSig);

                // Hold 상태 (XE_QUARANTINED) 또는 청산 등으로 강제 전이
                if(fakeSig.GetStatus() == XE_QUARANTINED) {
                    session.ForceTransition(SESSION_ACTIVE);
                } else if(fakeSig.GetXAExit() == XA_ACTIVE) {
                    session.ForceTransition(SESSION_LIQUIDATING);
                } else if(fakeSig.GetStatus() == XE_EXECUTED) {
                    session.ForceTransition(SESSION_ACTIVE);
                }
            } else {
                ICXSignal* prevSig = xp.GetSignal();
                xp.SetSignal(fakeSig);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("REVERSE-FAIL", xp, "Failed to borrow session"));
                xp.SetSignal(prevSig);

                delete fakeSig;
            }
        }

        while(zombies.Total() > 0) zombies.Detach(0);
        SAFE_DELETE(zombies);

        CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(ctx, "orchestrator", CXSequenceOrchestrator);
        return IS_VALID(orchestrator) ? orchestrator.ResolveId("WATCHER_ENTRY_DISCOVERY") : STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}

private:
    void ApplyChannelOptions(IDatabase* db, CXSignal* sig, int cno, int dir, bool isOrder) {
        if(IS_INVALID(db) || IS_INVALID(sig)) return;

        string sql = StringFormat("SELECT buy_entry_offset, sell_entry_offset, tp_points, sl_points, ts_trigger, ts_step, ikte_start, ikte_step FROM channel_options WHERE cno=%d", cno);
        int handle = db.GetHandle();
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
        }

        if(found) {
            sig.SetCno(cno);
            sig.SetDir(dir);
            if(isOrder) {
                double offset = (dir == CX_DIR_BUY) ? buy_entry_offset : sell_entry_offset;
                sig.SetTEStart(offset);
                sig.SetTEStep(100.0);
                sig.SetTELimit(1000.0);
                sig.SetTEInterval(1);
                
                sig.SetIkTeStart(0.0);
                sig.SetIkTeStep(0.0);
            } else {
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
        }
    }
};

#endif
