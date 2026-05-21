#ifndef CX_TASK_PENDING_V_SYNC_MQH
#define CX_TASK_PENDING_V_SYNC_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskPending_V_Sync
 * @brief [Verify] 터미널 실물 상태 동기화 및 외부 명령 감시
 */
class CXTaskPending_V_Sync : public IXTask {
public:
    virtual string Name() override { return "Pending_V_Sync"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        XP_LOG_TRACE(xp, StringFormat("[PENDING-V-SYNC] Monitoring SID:%s (Status:%d, XAExit:%d)", sig.GetSid(), sig.GetStatus(), sig.GetXAExit()));

        if(sig.GetStatus() == XE_ERROR) {
            XP_LOG_WARN(xp, "[PENDING-V-SYNC] ABORT: Signal is in XE_ERROR.");
            return SESSION_ERROR;
        }

        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_INFO(xp, "[PENDING-V-SYNC] OK: Exit command detected. Moving to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        if(sig.GetStatus() >= XE_EXECUTED) {
            XP_LOG_OK(xp, StringFormat("[PENDING-V-SYNC] OK: Signal executed (Status:%d). Moving to ACTIVE.", sig.GetStatus()));
            return SESSION_ACTIVE;
        }
        
        if(sig.GetTicket() <= 0) {
            XP_LOG_DEBUG(xp, "[PENDING-V-SYNC] BREAK: No ticket yet. Yielding...");
            return TASK_BREAK;
        }

        return TASK_CONTINUE;
    }
};

#endif
