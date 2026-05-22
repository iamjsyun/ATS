#ifndef CX_TASK_ENTRY_L_PRICE_MQH
#define CX_TASK_ENTRY_L_PRICE_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\ICXPriceManager.mqh"
#include "..\..\..\Interfaces\IXGuard.mqh"

/**
 * @class CXTaskEntry_L_Price
 * @brief [Logic] 진입 가격, SL, TP 계산 및 StopLevel 검증
 */
class CXTaskEntry_L_Price : public IXTask {
public:
    virtual string Name() override { return "Entry_L_Price"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXPriceManager* priceMgr = CX_GET_OBJ(ctx, "price_mgr", ICXPriceManager);
        IXGuard* guard = CX_GET_OBJ(ctx, "guard", IXGuard);

        if(IS_INVALID(sig) || IS_INVALID(priceMgr)) return TASK_BREAK;

        string symbol = sig.GetSymbol();
        int dir = sig.GetDir();
        double marketPrice = priceMgr.GetMarketPrice(symbol, dir);

        // 1. 실행 가격 계산 (Pending Order용 또는 Market용)
        // [v13.9 Refactoring] limit_offset을 삭제하고 te_start를 직접 사용
        double offset = sig.GetTEStart();
        double execPrice = priceMgr.CalculateExecPrice(xp, symbol, dir, sig.GetType(), offset);
        
        // 2. SL/TP 가격 계산 (BasePrice 기반)
        double basePrice = (sig.GetType() == ORDER_MARKET) ? marketPrice : execPrice;
        double finalSL = priceMgr.CalculateSL(xp, symbol, dir, basePrice, sig.GetSL());
        double finalTP = priceMgr.CalculateTP(xp, symbol, dir, basePrice, sig.GetTP());

        // 3. StopLevel 검증 및 보정 (10016 에러 방지)
        if(IS_VALID(guard)) {
            // 시장가 진입 시 Liquidation Price 기준으로 검증
            double vBase = (sig.GetType() == ORDER_MARKET) ? priceMgr.GetLiquidationPrice(symbol, dir) : basePrice;
            
            if(finalSL > 0 && !guard.ValidateStopLevel(symbol, vBase, finalSL)) {
                XP_LOG_WARN(xp, StringFormat("[ENTRY-L] SL too close (Base:%.5f, SL:%.5f). Resetting to 0.", vBase, finalSL));
                finalSL = 0;
            }
            if(finalTP > 0 && !guard.ValidateStopLevel(symbol, vBase, finalTP)) {
                XP_LOG_WARN(xp, StringFormat("[ENTRY-L] TP too close (Base:%.5f, TP:%.5f). Resetting to 0.", vBase, finalTP));
                finalTP = 0;
            }
        }

        // 4. 결과값 모델 동기화 (Shadowing)
        sig.SetPriceOpen(execPrice);
        sig.SetPriceSL(finalSL);
        sig.SetPriceTP(finalTP);

        XP_LOG_TRACE(xp, StringFormat("[ENTRY-L] Price Calculated: [Exec:%.5f, SL:%.5f, TP:%.5f]", execPrice, finalSL, finalTP));

        return TASK_CONTINUE;
    }
};

#endif
