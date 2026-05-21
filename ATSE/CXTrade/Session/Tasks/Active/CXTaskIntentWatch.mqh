#ifndef CX_TASK_INTENT_WATCH_MQH
#define CX_TASK_INTENT_WATCH_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskIntentWatch
 * @brief 외부 강제 청산 의도 모니터링
 */
class CXTaskIntentWatch : public IXTask {
public:
    virtual string Name() override { return "Task_IntentWatch"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || sig.GetStatus() == XE_ERROR) return TASK_BREAK;

        XP_LOG_TRACE(xp, StringFormat("[TASK-INTENT-WATCH] Checking External Intent for SID:%s (XAExit:%d)", sig.GetSid(), sig.GetXAExit()));

        if(sig.GetXAExit() == XA_ACTIVE) {
            CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), MSG_EXIT_REQUESTED);
            XP_LOG_INFO(xp, "[TASK-INTENT-WATCH] OK: Exit Command (XA_ACTIVE) Detected. Moving to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        return TASK_CONTINUE;
    }
};

#endif
