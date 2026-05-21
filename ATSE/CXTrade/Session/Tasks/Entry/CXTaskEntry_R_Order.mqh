#ifndef CX_TASK_ENTRY_R_ORDER_MQH
#define CX_TASK_ENTRY_R_ORDER_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXOrderManager.mqh"

/**
 * @class CXTaskEntry_R_Order
 * @brief [Request] 브로커에 주문 송신
 */
class CXTaskEntry_R_Order : public IXTask {
public:
    virtual string Name() override { return "Entry_R_Order"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        IXOrderManager* orderMgr = CX_GET_OBJ(ctx, "order_mgr", IXOrderManager);
        if(IS_INVALID(orderMgr)) {
            XP_LOG_ERROR(xp, "[ENTRY-R] FAILED: OrderManager context missing.");
            return TASK_BREAK;
        }

        ICXSignal* sig = xp.GetSignal();
        if(IS_VALID(sig) && (sig.GetTicket() > 0 || sig.GetStatus() >= XE_IN_TRANSIT)) {
            XP_LOG_DEBUG(xp, StringFormat("[ENTRY-R] SKIP: Asset already in transit (Ticket:%I64u, Status:%d)", 
                                          sig.GetTicket(), sig.GetStatus()));
            return TASK_CONTINUE;
        }

        XP_LOG_TRACE(xp, "[ENTRY-R] Sending Physical Order to Broker...");
        if(orderMgr.ExecuteEntry(xp)) {
            XP_LOG_OK(xp, "[ENTRY-R] SUCCESS: Order Request Sent.");
            return STATE_ENTRY_TRANSIT;
        }

        string lastErr = xp.GetString();
        if(lastErr == "") lastErr = "Broker Order Request Rejected";
        string finalErr = StringFormat("[ENTRY-R] FAILED: %s", lastErr);
        XP_LOG_ERROR(xp, finalErr);
        xp.SetString(finalErr);
        return SESSION_ERROR;
    }
};

#endif
