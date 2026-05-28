#ifndef CX_TASK_ACTIVE_L_TS_TRIGGER_WATCH_MQH
#define CX_TASK_ACTIVE_L_TS_TRIGGER_WATCH_MQH

#include "..\..\..\Platform\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXSymbolManager.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXPriceManager.mqh"
#include "..\..\..\Platform\Engine\Trailing\CXTrailingEngine.mqh"

/**
 * @class CXTaskActive_L_TS_TriggerWatch
 * @brief [Verify] 익절 트레일링(TS_START) 활성화 지점 감시 (v17.6)
 */
class CXTaskActive_L_TS_TriggerWatch : public IXTask {
public:
    virtual string Name() override { return "TS_TriggerWatch"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTSStart()) return TASK_BREAK;

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

        ENUM_TRAIL_STATE state = tsEngine.Update(currentPrice);
        if(state == TRAIL_STATE_ACTIVE || state == TRAIL_STATE_TRIGGERED) {
            double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? 1.0 : -1.0;
            double profit = (currentPrice - sig.GetPriceOpen()) * dir_sign;
            XP_LOG_OK(xp, CXAuditFormatter::Build("TS-WATCH", xp, StringFormat("TS Triggered via TrailingEngine! Profit %.0f pts >= TS_START %d pts", profit / point, (int)sig.GetTSStart())));
            return SESSION_TRAILING_STOP; // 익절 트레일링 상태로 전이
        }

        return TASK_CONTINUE;
    }
};

#endif
