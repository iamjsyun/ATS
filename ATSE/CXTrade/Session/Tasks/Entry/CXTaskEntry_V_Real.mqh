#ifndef CX_TASK_ENTRY_V_REAL_MQH
#define CX_TASK_ENTRY_V_REAL_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskEntry_V_Real
 * @brief [Verify] 터미널 내 실물 자산(Position/Order) 존재 확인 및 데이터 동기화
 */
class CXTaskEntry_V_Real : public IXTask {
public:
    virtual string Name() override { return "Entry_V_Real"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(sig) || IS_INVALID(invMgr)) {
            XP_LOG_ERROR(xp, "[ENTRY-V-REAL] FAILED: Required services missing.");
            return TASK_BREAK;
        }

        ulong ticket = (ulong)sig.GetTicket();
        
        // [v13.7 Resilience] Asset-Agnostic Check: Order 또는 Position 중 하나라도 존재하면 OK
        bool exists = invMgr.IsPositionExists(ticket) || invMgr.IsOrderExists(ticket);

        if(!exists) {
            // 실물이 전혀 없다면 히스토리를 즉시 확인 (수동 삭제/청산 대응)
            string reason = "";
            int histStatus = invMgr.CheckHistoryClosure(ticket, reason);
            if(histStatus != XE_UNKNOWN) {
                XP_LOG_WARN(xp, StringFormat("[ENTRY-V-REAL] ABORT: Asset found in history as %d (%s).", histStatus, reason));
                IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
                CXMessageProvider::UpdateStatus(sig, histStatus, reason);
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                return SESSION_LIQUIDATING;
            }

            if(IsTimedOut()) {
                XP_LOG_ERROR(xp, StringFormat("[ENTRY-V-REAL] FAILED: Ticket(%I64u) Verification Timeout.", ticket));
                return SESSION_ERROR;
            }
            return TASK_YIELD;
        }

        // 실물 데이터 동기화 (Shadowing) - 이제 어떤 형태든 살아있으면 동기화 후 다음 단계로
        invMgr.SyncToSignal(sig);
        XP_LOG_OK(xp, StringFormat("[ENTRY-V-REAL] SUCCESS: Ticket(%I64u) Confirmed and Synced.", ticket));

        return STATE_ENTRY_VERIFY;
    }
};

#endif
