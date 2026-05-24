#ifndef CX_TASK_EXIT_V_TERMINAL_MQH
#define CX_TASK_EXIT_V_TERMINAL_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskExit_V_Terminal
 * @brief [Verify] 터미널 내 실물 자산 소멸 확인 (L3 Verification)
 */
class CXTaskExit_V_Terminal : public IXTask {
public:
    virtual string Name() override { return "Exit_V_Terminal"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(sig) || IS_INVALID(invMgr)) return TASK_BREAK;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) {
            XP_LOG_TRACE(xp, CXAuditFormatter::Build("EXIT-V-TERM", xp, "SKIP: No ticket assigned."));
            return TASK_CONTINUE; 
        }

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("EXIT-V-TERM", xp, StringFormat("Verifying Absence: [Ticket:%I64u]", ticket)));

        bool exists = invMgr.IsAssetExists(ticket, sig.GetType());

        if(exists) {
            IncrementRetry();
            if(GetRetryCount() > 5) {
                string assetErr = StringFormat("Physical Asset(%I64u) still exists after max retries.", ticket);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("EXIT-V-TERM", xp, "FAILED: " + assetErr));
                if(IS_VALID(xp)) xp.SetString("[EXIT-V-TERM] " + assetErr);
                return SESSION_ERROR;
            }
            XP_LOG_DEBUG(xp, CXAuditFormatter::Build("EXIT-V-TERM", xp, StringFormat("Yield: Asset(%I64u) still active.", ticket)));
            return TASK_YIELD;
        }

        XP_LOG_OK(xp, CXAuditFormatter::Build("EXIT-V-TERM", xp, StringFormat("SUCCESS: Ticket(%I64u) Absence Verified.", ticket)));
        return STATE_EXIT_VERIFY; // Always jump to 23
    }
};

#endif
