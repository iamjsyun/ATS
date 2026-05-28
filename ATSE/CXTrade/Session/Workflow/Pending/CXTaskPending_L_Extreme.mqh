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
        if(IS_INVALID(sig) || 0 >= sig.GetTEStart() || xp.GetInt() == 10) return TASK_CONTINUE;

        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);
        double currentPrice = IS_VALID(priceMgr) ? priceMgr.GetLiquidationPrice(sig.GetSymbol(), sig.GetDir()) : SymbolInfoDouble(sig.GetSymbol(), (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_BID : SYMBOL_ASK);
        
        // [v16.28 Activation Guard] 진트 활성화 여부 확인 및 플래그 설정
        string activeKey = "TE_Active_" + sig.GetSid();
        bool isActive = false;
        ICXParam* pActive = ctx.GetParam(activeKey);
        if(IS_VALID(pActive) && pActive.GetInt() == 1) isActive = true;

        if(!isActive) {
            ICXSymbolManager* symMgr = CX_GET_OBJ(ctx, "sym_mgr", ICXSymbolManager);
            double point = IS_VALID(symMgr) ? symMgr.GetPoint(sig.GetSymbol()) : SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
            double dir_sign = (sig.GetDir() == CX_DIR_BUY) ? -1.0 : 1.0;
            
            double priceSignal = sig.GetPriceSignal();
            if(priceSignal <= 0) priceSignal = sig.GetPriceOpen() - (sig.GetTELimit() * point * dir_sign);
            
            double triggerPrice = priceSignal + (sig.GetTEStart() * point * dir_sign);
            
            bool triggerReached = (sig.GetDir() == CX_DIR_BUY) ? (currentPrice <= triggerPrice) : (currentPrice >= triggerPrice);
            
            if(triggerReached) {
                if(IS_INVALID(pActive)) {
                    pActive = new CXParam();
                    ctx.Set(activeKey, pActive);
                }
                pActive.SetInt(1);
                isActive = true;
                XP_LOG_OK(xp, CXAuditFormatter::Build("PEND-L-EXTR", xp, "Trailing Entry ACTIVATED!"));
            }
        }

        string extKey = "LastEntryExtremity_" + sig.GetSid();
        double lastExt = 0;
        ICXParam* pExt = ctx.GetParam(extKey);
        if(IS_VALID(pExt)) lastExt = pExt.GetDouble();

        ICXSymbolManager* symMgr = CX_GET_OBJ(ctx, "sym_mgr", ICXSymbolManager);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(sig.GetSymbol()) : SymbolInfoDouble(sig.GetSymbol(), SYMBOL_POINT);
        double stepDistance = sig.GetTEStep() * point;

        // [v1.1 Stepped Trailing Mandate] 유리한 방향으로 'te_step' 이상 움직였을 때만 극점 갱신
        bool is_new_extreme = false;
        if(lastExt <= 0) {
            is_new_extreme = true;
        } else {
            is_new_extreme = (sig.GetDir() == CX_DIR_BUY) ? (lastExt - currentPrice >= stepDistance)
                                                           : (currentPrice - lastExt >= stepDistance);
        }

        if(is_new_extreme) {
            if(IS_INVALID(pExt)) {
                pExt = new CXParam();
                ctx.Set(extKey, pExt);
            }
            pExt.SetDouble(currentPrice);
            if(isActive) {
                XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-L-EXTR", xp, 
                    StringFormat("New Trailing Extreme: %.5f (Prev: %.5f)", currentPrice, lastExt)));
            }
        }

        return TASK_CONTINUE;
    }
};

#endif
