#ifndef CX_TASK_ENTRY_V_TICKET_MQH
#define CX_TASK_ENTRY_V_TICKET_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskEntry_V_Ticket
 * @brief [Verify] 티켓 번호 획득 및 과도기 상태 검증
 */
class CXTaskEntry_V_Ticket : public IXTask {
public:
    virtual string Name() override { return "Entry_V_Ticket"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        // [v14.0 Exit-First Priority]
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_WARN(xp, "[ENTRY-V-TICKET] ABORT: Exit intent detected. Redirecting to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        ulong ticket = sig.GetTicket();
        XP_LOG_TRACE(xp, StringFormat("[ENTRY-V-TICKET] Verifying Ticket Acquisition... Current Ticket:%I64u", ticket));

        if(ticket <= 0) {
            if(IsTimedOut()) {
                XP_LOG_ERROR(xp, "[ENTRY-V-TICKET] FAILED: Ticket Acquisition Timeout.");
                return SESSION_ERROR;
            }
            XP_LOG_DEBUG(xp, "[ENTRY-V-TICKET] YIELD: Ticket not yet arrived. Waiting...");
            return TASK_YIELD;
        }

        XP_LOG_OK(xp, StringFormat("[ENTRY-V-TICKET] SUCCESS: Ticket %I64u Obtained.", ticket));
        CXMessageProvider::UpdateStatus(sig, XE_IN_TRANSIT, StringFormat("Ticket Obtained: %I64u. Verifying Asset...", ticket));
        return TASK_CONTINUE;
    }
};

#endif
