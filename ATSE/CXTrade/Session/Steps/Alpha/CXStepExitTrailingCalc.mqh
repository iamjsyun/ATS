#ifndef CXSTEPEXITTRAILINGCALC_MQH
#define CXSTEPEXITTRAILINGCALC_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Models\CXSignal.mqh"
#include "..\..\..\Interfaces\IXPriceTracker.mqh"

/**
 * @class CXStepExitTrailingCalc
 * @brief 익절 트레일링(TS) 가격 계산 전담 스텝 (Unified Direction Logic)
 */
class CXStepExitTrailingCalc : public IXStep {
public:
    virtual string Name() override { return "Step_ExitTrailingCalc"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        CXSignal* sig = CX_CAST(CXSignal, xp.GetSignal());
        return (IS_VALID(sig) && sig.GetStatus() >= XE_EXECUTED && sig.GetTSStart() > 0);
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        CXSignal* sig = CX_CAST(CXSignal, xp.GetSignal());
        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        if(IS_INVALID(sig) || IS_INVALID(tracker)) return STATE_UNCHANGED;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        //--- 방향성 추상화 (Buy: +1, Sell: -1 for profit)
        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
        double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;

        if(profit >= sig.GetTSStart() * point) {
            double peak = (sig.GetDir() == CX_DIR_BUY) ? tracker.GetHighest() : tracker.GetLowest();
            double target = peak - (sig.GetTSStart() * point * dir_sign);

            // 갱신 조건 검사 (Better SL check)
            bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target > sig.GetSL() + sig.GetTSStep() * point)
                                                       : (target < sig.GetSL() - sig.GetTSStep() * point || sig.GetSL() == 0);

            if(is_improved) {
                sig.SetSL(NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS)));
                return CALC_MODIFIED; // MODIFIED
            }
        }

        return CALC_NO_CHANGE; // NO_CHANGE
    }

    virtual void OnEnter(ICXContext* ctx) override {}
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif
