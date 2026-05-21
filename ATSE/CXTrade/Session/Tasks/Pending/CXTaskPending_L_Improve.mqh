#ifndef CX_TASK_PENDING_L_IMPROVE_MQH
#define CX_TASK_PENDING_L_IMPROVE_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXPriceTracker.mqh"

/**
 * @class CXTaskPending_L_Improve
 * @brief [Logic] 진입 트레일링 가격 개선 계산
 */
class CXTaskPending_L_Improve : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Improve"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || sig.GetTEStart() <= 0 || xp.GetInt() == 10) return TASK_CONTINUE;

        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        if(IS_INVALID(tracker)) return TASK_BREAK;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;
        double target = currentPrice + (sig.GetTEStart() * point * dir_sign);
        
        bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target < sig.GetPriceSignal() - sig.GetTEStep() * point) 
                                                        : (target > sig.GetPriceSignal() + sig.GetTEStep() * point);

        XP_LOG_TRACE(xp, StringFormat("[PENDING-L-IMPROVE] %s: Price:%.5f, Target:%.5f, Signal:%.5f, Improved:%d", 
                                      sig.GetSymbol(), currentPrice, target, sig.GetPriceSignal(), is_improved));

        if(is_improved) {
            double newPrice = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
            XP_LOG_INFO(xp, StringFormat("[PENDING-L-IMPROVE] OK: Price improvement detected: %.5f -> %.5f", sig.GetPriceSignal(), newPrice));
            xp.SetDouble(newPrice);
            xp.SetInt(1); 
        }

        return TASK_CONTINUE;
    }
};

#endif
