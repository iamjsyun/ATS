#ifndef CX_TASK_EXIT_L_PREPARE_MQH
#define CX_TASK_EXIT_L_PREPARE_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskExit_L_Prepare
 * @brief [Logic] 청산 조건 검증 및 준비 (I/O 없음)
 */
class CXTaskExit_L_Prepare : public IXTask {
public:
    virtual string Name() override { return "Exit_L_Prepare"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        XP_LOG_TRACE(xp, StringFormat("[EXIT-L-PREPARE] Checking Liquidation Intent for SID:%s (Status:%d, XAExit:%d)", 
                                      sig.GetSid(), sig.GetStatus(), sig.GetXAExit()));

        if(sig.GetStatus() >= XE_CLOSED_SIGNAL) {
            XP_LOG_DEBUG(xp, "[EXIT-L-PREPARE] SUCCESS: Already Closed. Moving to SESSION_CLOSED.");
            return SESSION_CLOSED;
        }

        if(sig.GetXAExit() != XA_ACTIVE) {
            XP_LOG_DEBUG(xp, "[EXIT-L-PREPARE] CONTINUE: Waiting for Exit Intent (XA_ACTIVE).");
            return TASK_CONTINUE; 
        }

        XP_LOG_INFO(xp, "[EXIT-L-PREPARE] OK: Liquidation Intent Confirmed.");
        return TASK_CONTINUE;
    }
};

#endif
