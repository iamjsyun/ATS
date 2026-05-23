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

        // [v14.6 Manual-Close Fast-Track]
        // 사용자가 수동으로 닫은 경우, EA가 직권으로 xa_exit=2를 마킹하여 App의 동기화 가속
        if(finalStatus == XE_CLOSED_MANUAL) {
            sig.SetXAExit(XA_CLOSED_COMPLETED); // 2
            XP_LOG_INFO(xp, "[EXIT-P] Manual Close Fast-Track: xa_exit set to 2.");
        }

        CXMessageProvider::UpdateStatus(sig, finalStatus, "Liquidation Finalized. Session Closed.");
        if(repo.UpdateStatus(sig)) {
            XP_LOG_OK(xp, StringFormat("[EXIT-P] Finalized Status: %d", finalStatus));
            return SESSION_CLOSED;
        }

        return TASK_YIELD; 
    }
};

#endif
