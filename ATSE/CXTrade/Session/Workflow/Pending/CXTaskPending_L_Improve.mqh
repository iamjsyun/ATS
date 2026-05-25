#ifndef CX_TASK_PENDING_L_IMPROVE_MQH
#define CX_TASK_PENDING_L_IMPROVE_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Core\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskPending_L_Improve
 * @brief [Logic] 진입 트레일링 가격 개선 계산
 */
class CXTaskPending_L_Improve : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Improve"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTEStart() || xp.GetInt() == 10) return TASK_CONTINUE;

        IXPriceTracker* tracker = CX_GET_OBJ(ctx, "price_tracker", IXPriceTracker);
        if(IS_INVALID(tracker)) return TASK_BREAK;

        double point = SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        tracker.Update(currentPrice);

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;
        
        // --- [v14.30 Bar-based Buffer Guard] ---
        // 1분봉 마감 시마다 최소 간격(ELIMIT) 유지 여부 체크
        string barKey = "LastBufferCheckBar_" + sig.GetSymbol();
        datetime lastBar = 0;
        ICXParam* pBar = ctx.GetParam(barKey);
        if(IS_VALID(pBar)) lastBar = (datetime)pBar.GetLong();

        double currentBar = (double)iTime(sig.GetSymbol(), PERIOD_M1, 0); // Cast to double for precision if needed, but datetime is long
        
        // Use GetPriceOpen() to compare against the ACTUAL current pending order price, not the original signal price
        double orderPrice = sig.GetPriceOpen(); 
        
        if((datetime)currentBar > lastBar) {
            double currentDist = MathAbs(currentPrice - orderPrice) / point;
            
            // ELIMIT(te_limit) 간격보다 좁아진 경우 (주문가가 현재가에 너무 가까움)
            if((double)sig.GetTELimit() >= currentDist) {
                double newTarget = currentPrice + (sig.GetTELimit() * point * dir_sign);
                double normTarget = NormalizeDouble(newTarget, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
                
                XP_LOG_INFO(xp, CXAuditFormatter::Build("PEND-L-BUFF", xp, StringFormat("Buffer Guard: Dist %.1f <= Limit %d. Pushing back to %.5f", currentDist, sig.GetTELimit(), normTarget)));
                xp.SetDouble(normTarget);
                xp.SetInt(1); // Trigger Modification
                
                CXParam* pNewBar = new CXParam();
                pNewBar.SetLong((long)currentBar);
                ctx.Set(barKey, pNewBar);
                
                // Buffer Guard가 작동하여 주문을 후퇴시켰으므로, 이번 틱에서는 기존 Trailing(전진) 로직 생략
                return TASK_CONTINUE;
            }
            
            CXParam* pNewBar = new CXParam();
            pNewBar.SetLong((long)currentBar);
            ctx.Set(barKey, pNewBar);
        }

        // --- [기존 Trailing Logic (Jint)] ---
        // ESTART(te_start) 간격 이상으로 유리해졌을 때만 주문가를 전진시킴
        double target = currentPrice + (sig.GetTEStart() * point * dir_sign);
        
        // 매수(Buy Limit): 타겟 가격이 현재 주문 가격보다 더 낮아졌는가? (더 싸게 살 수 있는가)
        // 매도(Sell Limit): 타겟 가격이 현재 주문 가격보다 더 높아졌는가? (더 비싸게 팔 수 있는가)
        bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target < orderPrice - (sig.GetTEStep() * point)) 
                                                        : (target > orderPrice + (sig.GetTEStep() * point));

        // 너무 잦은 로그 억제
        // XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-IMPR", xp, StringFormat("Price improvement check: Improved=%d", is_improved)));

        if(is_improved) {
            double newPrice = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
            
            XP_LOG_OK(xp, CXAuditFormatter::Build("ESTART-ACTIVE", xp, StringFormat("Trailing activated at %.5f (ESTART:%d pts reached). Moving from %.5f to %.5f", currentPrice, (int)sig.GetTEStart(), orderPrice, newPrice)));
            
            xp.SetDouble(newPrice);
            xp.SetInt(1); 
        }

        return TASK_CONTINUE;
    }
};

#endif
