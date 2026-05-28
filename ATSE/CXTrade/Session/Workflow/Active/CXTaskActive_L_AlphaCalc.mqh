#ifndef CX_TASK_ACTIVE_L_ALPHA_CALC_MQH
#define CX_TASK_ACTIVE_L_ALPHA_CALC_MQH

#include "..\..\..\Platform\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\..\Platform\Core\Interfaces\IXPriceTracker.mqh"
#include "..\..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXSymbolManager.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXPriceManager.mqh"
#include "..\..\..\Platform\Engine\Trailing\CXTrailingEngine.mqh"

/**
 * @class CXTaskActive_L_AlphaCalc
 * @brief 알파(익절 트레일링) 로직 계산 (Pure Logic)
 */
class CXTaskActive_L_AlphaCalc : public IXTask {
public:
    virtual string Name() override { return "Task_AlphaCalc"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        //--- [v14.34 Fix] Error-State Liquidation Bypass
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_INFO(xp, CXAuditFormatter::Build("ALPHA-CALC", xp, "Exit intent detected. Redirecting to LIQUIDATING."));
            return SESSION_LIQUIDATING;
        }

        if(sig.GetStatus() == XE_ERROR) return TASK_BREAK;
        
        // [v16.4 Scenario C] Quarantine Hold: 알파 계산 중단
        if(sig.GetStatus() == XE_QUARANTINED) return TASK_BREAK;

        if(0 >= sig.GetTSStart()) return TASK_BREAK;

        ICXSymbolManager* symMgr = CX_GET_OBJ(ctx, "sym_mgr", ICXSymbolManager);
        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);

        double point = IS_VALID(symMgr) ? symMgr.GetPoint(sig.GetSymbol()) : SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double currentPrice = IS_VALID(priceMgr) ? priceMgr.GetLiquidationPrice(sig.GetSymbol(), sig.GetDir()) : SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        string tsEngineKey = "TSEngine_" + sig.GetSid();
        CXTrailingEngine* tsEngine = CX_CAST(CXTrailingEngine, ctx.Get(tsEngineKey));
        if(IS_INVALID(tsEngine)) {
            tsEngine = new CXTrailingEngine(TRAIL_MODE_EXIT, sig.GetDir(), point);
            tsEngine.Configure(sig.GetPriceOpen(), sig.GetTSStart(), sig.GetTSStep());
            ctx.Set(tsEngineKey, tsEngine);
        }

        tsEngine.Update(currentPrice);

        double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
        double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("ALPHA-CALC", xp, StringFormat("Tracking via TrailingEngine: Profit %.0f pts", profit / point)));

        if(profit >= sig.GetTSStart() * point) {
            double peak = tsEngine.GetExtreme();
            double target = peak - (sig.GetTSStart() * point * dir_sign);

            bool is_improved = false;
            if(sig.GetSL() == 0) {
                is_improved = true;
            } else {
                is_improved = (sig.GetDir() == CX_DIR_BUY) ? (target - sig.GetSL() >= sig.GetTSStep() * point)
                                                           : (sig.GetSL() - target >= sig.GetTSStep() * point);
            }

            if(is_improved) {
                int digits = IS_VALID(symMgr) ? symMgr.GetDigits(sig.GetSymbol()) : (int)SymbolInfoInteger(sig.GetSymbol(), SYMBOL_DIGITS);
                double newSL = NormalizeDouble(target, digits);
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
