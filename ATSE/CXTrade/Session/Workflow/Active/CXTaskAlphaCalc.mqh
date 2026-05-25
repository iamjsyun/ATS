#ifndef CX_TASK_ALPHA_CALC_MQH
#define CX_TASK_ALPHA_CALC_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Core\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskAlphaCalc
 * @brief 알파(익절 트레일링) 로직 계산 (Pure Logic)
 */
class CXTaskAlphaCalc : public IXTask {
public:
    virtual string Name() override { return "Task_AlphaCalc"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || sig.GetStatus() == XE_ERROR) return TASK_BREAK;
        
        // [v16.4 Scenario C] Quarantine Hold: 알파 계산 중단
        if(sig.GetStatus() == XE_QUARANTINED) return TASK_BREAK;

        if(0 >= sig.GetTSStart()) return TASK_BREAK;

        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        if(IS_INVALID(tracker)) return TASK_BREAK;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
        double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("ALPHA-CALC", xp, StringFormat("Tracking: Profit %.0f pts", profit / point)));

        if(profit >= sig.GetTSStart() * point) {
            double peak = (sig.GetDir() == CX_DIR_BUY) ? tracker.GetHighest() : tracker.GetLowest();
            double target = peak - (sig.GetTSStart() * point * dir_sign);

            bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target >= sig.GetSL() + sig.GetTSStep() * point)
                                                            : (sig.GetSL() - sig.GetTSStep() * point >= target || sig.GetSL() == 0);

            if(is_improved) {
                double newSL = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
                XP_LOG_INFO(xp, CXAuditFormatter::Build("ALPHA-CALC", xp, StringFormat("OK: SL Target improved to %.5f", newSL)));
                xp.SetDouble(newSL);
                return TASK_CONTINUE;
            }
        }

        xp.SetDouble(0); 
        return TASK_CONTINUE;
    }
};

#endif
