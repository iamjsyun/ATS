#ifndef CX_TASK_ENTRY_P_FINALIZE_MQH
#define CX_TASK_ENTRY_P_FINALIZE_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Core\Interfaces\IRepository.mqh"
#include "..\..\..\Shared\Logging\CXMessageProvider.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskEntry_P_Finalize
 * @brief [Persistence] DB 상태 최종 확정
 */
class CXTaskEntry_P_Finalize : public IXTask {
public:
    virtual string Name() override { return "Entry_P_Finalize"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(repo)) return TASK_BREAK;

        int targetStatus = (sig.GetType() == ORDER_MARKET) ? XE_EXECUTED : XE_PENDING_PLACED;
        string msg = (targetStatus == XE_EXECUTED) ? "Entry Executed (Market)" : "Entry Pending Placed (Trailing)";
        int nextSessionPhase = (targetStatus == XE_EXECUTED) ? SESSION_ACTIVE : TASK_CONTINUE;

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("TASK-FINALIZE", xp, StringFormat("Committing Final State: %d (%s)", targetStatus, msg)));

        CXMessageProvider::UpdateStatus(sig, targetStatus, msg);
        if(repo.UpdateStatus(sig)) {
            XP_LOG_OK(xp, CXAuditFormatter::Build("TASK-FINALIZE", xp, StringFormat("SUCCESS: DB Updated. Result: %d", nextSessionPhase)));
            return nextSessionPhase;
        }

        XP_LOG_WARN(xp, CXAuditFormatter::Build("TASK-FINALIZE", xp, "YIELD: DB Update Delayed. Retrying..."));
        return TASK_YIELD;
    }
};

#endif
