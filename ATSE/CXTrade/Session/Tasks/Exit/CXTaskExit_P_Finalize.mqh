#ifndef CX_TASK_EXIT_P_FINALIZE_MQH
#define CX_TASK_EXIT_P_FINALIZE_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskExit_P_Finalize
 * @brief [Persistence] DB 상태 최종 확정 (CLOSED)
 */
class CXTaskExit_P_Finalize : public IXTask {
public:
    virtual string Name() override { return "Exit_P_Finalize"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(repo)) return TASK_BREAK;

        int finalStatus = sig.GetStatus();
        if(finalStatus < XE_CLOSED_SIGNAL) finalStatus = XE_CLOSED_SIGNAL;

        CXMessageProvider::UpdateStatus(sig, finalStatus, "Liquidation Finalized. Session Closed.");
        if(repo.UpdateStatus(sig)) {
            XP_LOG_OK(xp, StringFormat("[EXIT-P] Finalized Status: %d", finalStatus));
            return SESSION_CLOSED;
        }

        return TASK_YIELD; 
    }
};

#endif
