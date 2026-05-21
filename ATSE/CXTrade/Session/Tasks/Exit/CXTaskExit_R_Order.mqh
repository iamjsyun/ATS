#ifndef CX_TASK_EXIT_R_ORDER_MQH
#define CX_TASK_EXIT_R_ORDER_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXExitManager.mqh"

/**
 * @class CXTaskExit_R_Order
 * @brief [Request] 브로커에 청산(Close/Cancel) 주문 송신
 */
class CXTaskExit_R_Order : public IXTask {
public:
    virtual string Name() override { return "Exit_R_Order"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
        if(IS_INVALID(exitMgr)) {
            XP_LOG_ERROR(xp, "[EXIT-R-ORDER] FAILED: ExitManager context missing.");
            return TASK_BREAK;
        }

        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        if(xp.GetInt() == 3) {
            XP_LOG_DEBUG(xp, "[EXIT-R-ORDER] SKIP: Order already sent in previous pulse.");
            return TASK_CONTINUE;
        }

        XP_LOG_TRACE(xp, StringFormat("[EXIT-R-ORDER] Sending Liquidation Order to Broker for Ticket:%I64u...", sig.GetTicket()));
        if(exitMgr.CloseByTicket(xp, sig)) {
            XP_LOG_OK(xp, "[EXIT-R-ORDER] SUCCESS: Liquidation Request Sent.");
            xp.SetInt(3); 
            return STATE_LIQUIDATING_TRANSIT;
        }

        string lastErr = xp.GetString();
        if(lastErr == "") lastErr = "Broker Liquidation Request Rejected";
        string finalErr = StringFormat("[EXIT-R-ORDER] FAILED: %s", lastErr);
        XP_LOG_ERROR(xp, finalErr);
        xp.SetString(finalErr);
        return SESSION_ERROR;
    }
};

#endif
