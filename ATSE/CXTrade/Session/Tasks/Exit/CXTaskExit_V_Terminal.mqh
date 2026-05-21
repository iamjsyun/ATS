#ifndef CX_TASK_EXIT_V_TERMINAL_MQH
#define CX_TASK_EXIT_V_TERMINAL_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskExit_V_Terminal
 * @brief [Verify] 터미널 내 실물 자산 소멸 확인 (L3 Verification)
 */
class CXTaskExit_V_Terminal : public IXTask {
public:
    virtual string Name() override { return "Exit_V_Terminal"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) {
            XP_LOG_DEBUG(xp, "[EXIT-V-TERMINAL] SKIP: No ticket assigned.");
            return TASK_CONTINUE; 
        }

        XP_LOG_TRACE(xp, StringFormat("[EXIT-V-TERMINAL] Verifying Physical Asset(%I64u) Absence... (Retry:%d)", ticket, GetRetryCount()));

        bool exists = false;
        if(sig.GetType() == ORDER_MARKET) {
            exists = PositionSelectByTicket(ticket);
        } else {
            exists = OrderSelect(ticket);
        }

        if(exists) {
            IncrementRetry();
            if(GetRetryCount() > 5) {
                XP_LOG_ERROR(xp, StringFormat("[EXIT-V-TERMINAL] FAILED: Physical Asset(%I64u) still exists after 5 retries.", ticket));
                return SESSION_ERROR;
            }
            XP_LOG_DEBUG(xp, StringFormat("[EXIT-V-TERMINAL] YIELD: Asset(%I64u) still in terminal. Waiting...", ticket));
            return TASK_YIELD;
        }

        XP_LOG_OK(xp, StringFormat("[EXIT-V-TERMINAL] SUCCESS: Physical Asset(%I64u) Absence Verified.", ticket));
        return STATE_EXIT_VERIFY;
    }
};

#endif
