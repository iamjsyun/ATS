#ifndef CX_TASK_PENDING_L_REBOUND_MQH
#define CX_TASK_PENDING_L_REBOUND_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskPending_L_Rebound
 * @brief [Logic] 반등 감지 (Market 전환 여부 판단)
 */
class CXTaskPending_L_Rebound : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Rebound"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTEStart()) return TASK_CONTINUE;

        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        if(IS_INVALID(tracker)) return TASK_BREAK;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        // [v14.31 Spec Sync] Rebound is calculated from the extreme point (Bottom/Peak)
        double extreme = (sig.GetDir() == CX_DIR_BUY) ? tracker.GetLowest() : tracker.GetHighest();
        bool is_rebounded = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice >= extreme + (sig.GetTEStep() * point))
                                                         : (extreme - (sig.GetTEStep() * point) >= currentPrice);

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, StringFormat("Price rebound check: Extreme=%.5f, Rebounded=%d", extreme, is_rebounded)));

        if(is_rebounded) {
            XP_LOG_INFO(xp, CXAuditFormatter::Build("PEND-L-REBD", xp, "Market Fallback Triggered."));
            xp.SetInt(10); 
        }

        return TASK_CONTINUE;
    }
};

#endif
