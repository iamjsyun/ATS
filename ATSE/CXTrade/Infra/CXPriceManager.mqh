#ifndef CXPRICEMANAGER_MQH
#define CXPRICEMANAGER_MQH

#include "..\Interfaces\ICXPriceManager.mqh"
#include "..\Interfaces\ICXPriceManager.mqh"
#include "..\Interfaces\ICXSymbolManager.mqh"
#include "..\Interfaces\ICXContext.mqh"
#include "..\Interfaces\CXDefine.mqh"
#include "..\Interfaces\CXMacros.mqh"

/**
 * @class CXPriceManager
 * @brief 가격 계산 및 무결성 검증 전문 구현체
 */
class CXPriceManager : public ICXPriceManager {
private:
    ICXContext* m_ctx;

public:
    CXPriceManager(ICXContext* ctx) : m_ctx(ctx) {}
    virtual ~CXPriceManager() {}

    /**
     * @brief 방향에 따른 실시간 시장가 추출 (Ask/Bid)
     */
    virtual double GetMarketPrice(string symbol, int dir) override {
        double currentAsk = SymbolInfoDouble(symbol, SYMBOL_ASK);
        double currentBid = SymbolInfoDouble(symbol, SYMBOL_BID);
        return (dir == CX_DIR_BUY) ? currentAsk : currentBid;
    }

    /**
     * @brief 포인트 값을 절대 가격 오프셋으로 변환
     */
    virtual double PointsToPrice(string symbol, int points) override {
        ICXSymbolManager* symMgr = CX_GET_OBJ(m_ctx, "sym_mgr", ICXSymbolManager);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(symbol) : SymbolInfoDouble(symbol, SYMBOL_POINT);
        return points * point;
    }

    /**
     * @brief 오더 실행가 계산 (v11.0: 시장가 기반 동적 산출)
     */
    virtual double CalculateExecPrice(ICXParam* xp, string symbol, int dir, int type, double offsetPts) override {
        ICXSymbolManager* symMgr = CX_GET_OBJ(m_ctx, "sym_mgr", ICXSymbolManager);
        double marketPrice = GetMarketPrice(symbol, dir);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(symbol) : SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digits = IS_VALID(symMgr) ? symMgr.GetDigits(symbol) : (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        
        if(type == ORDER_MARKET) return marketPrice;

        double dir_sign = (dir == CX_DIR_BUY) ? 1.0 : -1.0;
        double execPrice = NormalizeDouble(marketPrice - (offsetPts * point * dir_sign), digits);

        // [v11.1 Guard] invalid price 사전 차단 (매수 지정가가 시장가보다 높거나 매도 지정가가 시장가보다 낮은 경우)
        if(dir == CX_DIR_BUY && execPrice > marketPrice) {
            XP_LOG_WARN(xp, StringFormat("[PRICE-MGR] Correcting BUY_LIMIT: ExecPrice(%.5f) > Market(%.5f) -> Forced to Market", execPrice, marketPrice));
            execPrice = marketPrice;
        }
        else if(dir == CX_DIR_SELL && execPrice < marketPrice) {
            XP_LOG_WARN(xp, StringFormat("[PRICE-MGR] Correcting SELL_LIMIT: ExecPrice(%.5f) < Market(%.5f) -> Forced to Market", execPrice, marketPrice));
            execPrice = marketPrice;
        }

        XP_LOG_TRACE(xp, StringFormat("[PRICE-MGR] ExecPrice: Mkt:%.5f, Off:%.0f pts -> Exec:%.5f", marketPrice, offsetPts, execPrice));
        return execPrice;
    }

    /**
     * @brief 실행가 기준 SL 계산
     */
    virtual double CalculateSL(ICXParam* xp, string symbol, int dir, double basePrice, double slPts) override {
        if(slPts <= 0) return 0;
        
        ICXSymbolManager* symMgr = CX_GET_OBJ(m_ctx, "sym_mgr", ICXSymbolManager);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(symbol) : SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digits = IS_VALID(symMgr) ? symMgr.GetDigits(symbol) : (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        double dir_sign = (dir == CX_DIR_BUY) ? 1.0 : -1.0;

        double sl = NormalizeDouble(basePrice - (slPts * point * dir_sign), digits);
        XP_LOG_TRACE(xp, StringFormat("[PRICE-MGR] SL: Base:%.5f, Off:%.0f pts -> SL:%.5f", basePrice, slPts, sl));
        return sl;
    }

    /**
     * @brief 실행가 기준 TP 계산
     */
    virtual double CalculateTP(ICXParam* xp, string symbol, int dir, double basePrice, double tpPts) override {
        if(tpPts <= 0) return 0;

        ICXSymbolManager* symMgr = CX_GET_OBJ(m_ctx, "sym_mgr", ICXSymbolManager);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(symbol) : SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digits = IS_VALID(symMgr) ? symMgr.GetDigits(symbol) : (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        double dir_sign = (dir == CX_DIR_BUY) ? 1.0 : -1.0;

        double tp = NormalizeDouble(basePrice + (tpPts * point * dir_sign), digits);
        XP_LOG_TRACE(xp, StringFormat("[PRICE-MGR] TP: Base:%.5f, Off:%.0f pts -> TP:%.5f", basePrice, tpPts, tp));
        return tp;
    }
};

#endif
