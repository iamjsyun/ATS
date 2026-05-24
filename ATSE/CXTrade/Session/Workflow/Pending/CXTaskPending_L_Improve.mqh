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
        CObject* objBar = ctx.Get(barKey);
        if(IS_VALID(objBar)) {
            CXParam* pBar = dynamic_cast<CXParam*>(objBar);
            if(IS_VALID(pBar)) lastBar = (datetime)pBar.GetLong();
        }

        datetime currentBar = iTime(sig.GetSymbol(), PERIOD_M1, 0);
        if(currentBar > lastBar) {
            double currentDist = MathAbs(currentPrice - sig.GetPriceSignal()) / point;
            if((double)sig.GetTELimit() >= currentDist) {
                double newTarget = currentPrice + (sig.GetTELimit() * point * dir_sign);
                double normTarget = NormalizeDouble(newTarget, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
                
                XP_LOG_INFO(xp, CXAuditFormatter::Build("PEND-L-BUFF", xp, StringFormat("Buffer Guard: Dist %.1f < Limit %d. Pushing back to %.5f", currentDist, sig.GetTELimit(), normTarget)));
                xp.SetDouble(normTarget);
                xp.SetInt(1); // Trigger Modification
                
                // Update last bar time to prevent multiple triggers in same bar
                CXParam* pNewBar = new CXParam();
                pNewBar.SetLong((long)currentBar);
                ctx.Set(barKey, pNewBar);
                return TASK_CONTINUE;
            }
            
            // Just update bar time if no violation
            CXParam* pNewBar = new CXParam();
            pNewBar.SetLong((long)currentBar);
            ctx.Set(barKey, pNewBar);
        }

        // --- [기존 Trailing Logic] ---
        // [v14.31 Spec Sync] Trailing threshold check.
        // Price must improve by at least ESTART before moving the order.
        double target = currentPrice + (sig.GetTEStart() * point * dir_sign);
        
        bool is_improved = (sig.GetDir() == CX_DIR_BUY) ? (sig.GetPriceSignal() - sig.GetTEStart() * point >= target) 
                                                        : (target >= sig.GetPriceSignal() + sig.GetTEStart() * point);

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-IMPR", xp, StringFormat("Price improvement check: Improved=%d", is_improved)));

        if(is_improved) {
            double newPrice = NormalizeDouble(target, (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS));
            
            // [v14.33 Event Log] Record Trailing Activation
            XP_LOG_OK(xp, CXAuditFormatter::Build("ESTART-ACTIVE", xp, StringFormat("Trailing activated at %.5f (ESTART:%d pts reached)", currentPrice, (int)sig.GetTEStart())));
            
            XP_LOG_INFO(xp, CXAuditFormatter::Build("PEND-L-IMPR", xp, StringFormat("OK: Price Target improved to %.5f", newPrice)));
            xp.SetDouble(newPrice);
            xp.SetInt(1); 
        }

        return TASK_CONTINUE;
    }
};

#endif
