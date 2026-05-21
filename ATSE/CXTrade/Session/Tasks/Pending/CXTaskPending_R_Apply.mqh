#ifndef CX_TASK_PENDING_R_APPLY_MQH
#define CX_TASK_PENDING_R_APPLY_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXOrderManager.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskPending_R_Apply
 * @brief [Request] 계산된 가격을 브로커에 적용 및 DB 기록
 */
class CXTaskPending_R_Apply : public IXTask {
public:
    virtual string Name() override { return "Pending_R_Apply"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IXOrderManager* orderMgr = CX_GET_OBJ(ctx, "order_mgr", IXOrderManager);
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(orderMgr)) return TASK_BREAK;

        int flag = xp.GetInt(); 
        
        if(flag == 10) {
            XP_LOG_TRACE(xp, "[PENDING-R-APPLY] Processing Market Fallback due to rebound...");
            if(orderMgr.DeleteOrder(xp, (ulong)sig.GetTicket())) {
                //-- [v10.31] Do not switch to Market order. Keep it as Limit order, but apply te_limit offset.
                sig.SetLimitOffset(sig.GetTELimit());
                if(orderMgr.ExecuteEntry(xp)) {
                    if(IS_VALID(repo)) repo.UpdateStatus(sig);
                    XP_LOG_OK(xp, "[PENDING-R-APPLY] SUCCESS: Fallback to Limit executed (Offset replaced).");
                    return SESSION_ACTIVE;
                }
            }
            
            string lastErr = xp.GetString();
            if(lastErr == "") lastErr = "Market Fallback attempt failed";
            string finalErr = StringFormat("[PENDING-R-APPLY] FAILED: %s", lastErr);
            XP_LOG_ERROR(xp, finalErr);
            xp.SetString(finalErr);
            return SESSION_ERROR;
        }

        double newPrice = xp.GetDouble();
        if(newPrice > 0) {
            XP_LOG_TRACE(xp, StringFormat("[PENDING-R-APPLY] Attempting Order Modify: %.5f -> %.5f", sig.GetPriceSignal(), newPrice));
            IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);
            
            //--- [v10.10 Fix] SL/TP Point-to-Price Calculation for Modification
            double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
            double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
            double finalSL = sig.GetPriceSL();
            double finalTP = sig.GetPriceTP();

            if(finalSL <= 0 && sig.GetSL() > 0) finalSL = NormalizeDouble(newPrice - (sig.GetSL() * point * dir_sign), (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
            if(finalTP <= 0 && sig.GetTP() > 0) finalTP = NormalizeDouble(newPrice + (sig.GetTP() * point * dir_sign), (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));

            if(IS_VALID(guard) && !guard.ValidateStopLevel(sig.GetSymbol(), newPrice, finalSL)) {
                string guardErr = StringFormat("[PENDING-R-APPLY] FAILED: StopLevel Violation for Price Update. P:%.5f, SL:%.5f", newPrice, finalSL);
                XP_LOG_WARN(xp, guardErr);
                xp.SetString(guardErr);
                return TASK_BREAK;
            }

            if(orderMgr.ModifyOrder(xp, (ulong)sig.GetTicket(), newPrice, finalSL, finalTP)) {
                sig.UpdatePriceSignal(newPrice);
                sig.SetSL(finalSL); // Update cached SL/TP prices if changed
                sig.SetTP(finalTP);
                CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), MSG_ENTRY_TRAILING_MODIFIED);
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                XP_LOG_OK(xp, StringFormat("[PENDING-R-APPLY] SUCCESS: Order Modified to %.5f", newPrice));
            } else {
                string modErr = StringFormat("[PENDING-R-APPLY] FAILED: Broker rejected price modification to %.5f", newPrice);
                XP_LOG_ERROR(xp, modErr);
                xp.SetString(modErr);
            }
        }

        return TASK_CONTINUE;
    }
};

#endif
