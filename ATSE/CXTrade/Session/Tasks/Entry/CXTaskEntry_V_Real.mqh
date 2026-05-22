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

        // [v14.0 Exit-First Priority]
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_WARN(xp, "[ENTRY-V-REAL] ABORT: Exit intent detected. Redirecting to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        ulong ticket = (ulong)sig.GetTicket();
        
        // [v13.7 Resilience] Asset-Agnostic Check: Order 또는 Position 중 하나라도 존재하면 OK
        bool exists = invMgr.IsPositionExists(ticket) || invMgr.IsOrderExists(ticket);

        if(!exists) {
            // [v13.9 Heartbeat] DB에 현재 진행 상황 보고 (Stuck 현상 가시화)
            string retryKey = StringFormat("VRealRetry_%I64u", ticket);
            int retryCount = 0;
            CObject* obj = ctx.Get(retryKey);
            if(IS_VALID(obj)) {
                CXParam* pOld = dynamic_cast<CXParam*>(obj);
                if(IS_VALID(pOld)) retryCount = pOld.GetInt();
            }

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
                string timeoutErr = StringFormat("[ENTRY-V-REAL] FAILED: Ticket(%I64u) Verification Timeout.", ticket);
                XP_LOG_ERROR(xp, timeoutErr);
                if(IS_VALID(xp)) xp.SetString(timeoutErr);
                return SESSION_ERROR;
            }

            // Yield 상태 보고
            retryCount++;
            CXParam* pNew = new CXParam();
            pNew.SetInt(retryCount);
            ctx.Set(retryKey, pNew);
            
            IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
            CXMessageProvider::UpdateStatus(sig, XE_IN_TRANSIT, StringFormat("Verifying Asset... (Retry:%d)", retryCount));
            if(IS_VALID(repo)) repo.UpdateStatus(sig);

            return TASK_YIELD;
        }

        // 실물 데이터 동기화 (Shadowing) - 이제 어떤 형태든 살아있으면 동기화 후 다음 단계로
        invMgr.SyncToSignal(sig);
        XP_LOG_OK(xp, StringFormat("[ENTRY-V-REAL] SUCCESS: Ticket(%I64u) Confirmed and Synced.", ticket));

        return STATE_ENTRY_VERIFY;
    }
};

#endif
