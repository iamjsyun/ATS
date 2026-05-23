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
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(exitMgr) || IS_INVALID(invMgr)) {
            XP_LOG_ERROR(xp, "[EXIT-R-ORDER] FAILED: Required context missing.");
            return TASK_BREAK;
        }

        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        // [v14.4 Idempotency Guard] 이미 요청이 나갔다면 중복 송신 차단
        if(xp.GetInt() == 3) {
            XP_LOG_DEBUG(xp, "[EXIT-R-ORDER] SKIP: Liquidation already requested. Moving to Transit.");
            return STATE_LIQUIDATING_TRANSIT;
        }

        // [v14.4 Physical Asset Guard] 티켓이 이미 없다면 송신할 필요 없음
        ulong ticket = (ulong)sig.GetTicket();
        if(ticket > 0 && !invMgr.IsAssetExists(ticket, sig.GetType())) {
            XP_LOG_WARN(xp, StringFormat("[EXIT-R-ORDER] Physical Asset(%I64u) already gone. Skipping Request.", ticket));
            return STATE_LIQUIDATING_TRANSIT; 
        }

        XP_LOG_TRACE(xp, StringFormat("[EXIT-R-ORDER] Sending Liquidation Order for Ticket:%I64u...", ticket));
        if(exitMgr.CloseByTicket(xp, sig)) {
            XP_LOG_OK(xp, "[EXIT-R-ORDER] SUCCESS: Liquidation Request Sent.");
            xp.SetInt(3); // Mark as requested
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
