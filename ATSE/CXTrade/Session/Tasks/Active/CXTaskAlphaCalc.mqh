#ifndef CX_TASK_ALPHA_CALC_MQH
#define CX_TASK_ALPHA_CALC_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXPriceTracker.mqh"

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

        if(sig.GetTSStart() <= 0) return TASK_BREAK;

        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        if(IS_INVALID(tracker)) return TASK_BREAK;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
        double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;

        XP_LOG_TRACE(xp, StringFormat("[TASK-ALPHA-CALC] Tracking %s: P:%.5f, Peak:%.5f, Profit:%.0f pts", 
                                      sig.GetSymbol(), currentPrice, tracker.GetHighest(), profit / point));

        if(profit >= sig.GetTSStart() * point) {
            double peak = (sig.GetDir() == CX_DIR_BUY) ? tracker.GetHighest() : tracker.GetLowest();
            double target = peak - (sig.GetTSStart() * point * dir_sign);

            bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target > sig.GetSL() + sig.GetTSStep() * point)
                                                            : (target < sig.GetSL() - sig.GetTSStep() * point || sig.GetSL() == 0);

            if(is_improved) {
                double newSL = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
                XP_LOG_INFO(xp, StringFormat("[TASK-ALPHA-CALC] OK: SL Improvement Target: %.5f -> %.5f", sig.GetSL(), newSL));
                xp.SetDouble(newSL);
                return TASK_CONTINUE;
            }
        }

        xp.SetDouble(0); 
        return TASK_CONTINUE;
    }
};

#endif
