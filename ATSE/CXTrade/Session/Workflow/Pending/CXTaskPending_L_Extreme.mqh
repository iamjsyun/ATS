#ifndef CX_TASK_PENDING_L_EXTREME_MQH
#define CX_TASK_PENDING_L_EXTREME_MQH

#include "..\..\..\Platform\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Platform\Core\Macros\CXMacros.mqh"
#include "..\..\..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\..\Platform\Core\Interfaces\ICXPriceManager.mqh"

/**
 * @class CXTaskPending_L_Extreme
 * @brief [Logic] 진입을 위한 유리한 가격 극점 추적 (v17.6)
 */
class CXTaskPending_L_Extreme : public IXTask {
public:
    virtual string Name() override { return "Pending_L_Extreme"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig) || 0 >= sig.GetTEStart()) return TASK_CONTINUE;

        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);
        double currentPrice = IS_VALID(priceMgr) ? priceMgr.GetLiquidationPrice(sig.GetSymbol(), sig.GetDir()) : SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        string extKey = "LastEntryExtremity_" + sig.GetSid();
        double lastExt = 0;
        ICXParam* pExt = ctx.GetParam(extKey);
        if(IS_VALID(pExt)) lastExt = pExt.GetDouble();

        // 유리한 방향(Buy: 하락, Sell: 상승)으로 가격이 갱신되는지 확인
        bool is_new_extreme = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice < lastExt || lastExt <= 0)
                                                           : (currentPrice > lastExt || lastExt <= 0);

        if(is_new_extreme) {
            if(IS_INVALID(pExt)) {
                pExt = new CXParam();
                ctx.Set(extKey, pExt);
            }
            pExt.SetDouble(currentPrice);
            XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-EXTR", xp, StringFormat("New Extreme Tracked: %.5f", currentPrice)));
        }

        return TASK_CONTINUE;
    }
};

#endif
