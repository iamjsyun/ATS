#ifndef CXINVENTORYMANAGER_MQH
#define CXINVENTORYMANAGER_MQH

#include "..\Interfaces\ICXInventoryManager.mqh"
#include "..\Interfaces\CXDefine.mqh"

/**
 * @class CXInventoryManager
 * @brief 터미널 실물 자산 상태 확인 및 동기화 구현체
 */
class CXInventoryManager : public ICXInventoryManager {
public:
    CXInventoryManager() {}
    virtual ~CXInventoryManager() {}

    virtual bool IsPositionExists(ulong ticket) override {
        return PositionSelectByTicket(ticket);
    }

    virtual bool IsOrderExists(ulong ticket) override {
        return OrderSelect(ticket);
    }

    virtual bool IsAssetExists(ulong ticket, int type) override {
        if(ticket <= 0) return false;
        return (type == ORDER_MARKET) ? IsPositionExists(ticket) : IsOrderExists(ticket);
    }

    /**
     * @brief 실물 자산의 데이터를 내부 신호 모델에 동기화 (Shadowing)
     */
    virtual bool SyncToSignal(ICXSignal* sig) override {
        if(IS_INVALID(sig)) return false;
        
        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) return false;

        // 1. 포지션 동기화 (체결된 상태)
        if(PositionSelectByTicket(ticket)) {
            sig.SetLot(PositionGetDouble(POSITION_VOLUME));
            sig.SetPriceOpen(PositionGetDouble(POSITION_PRICE_OPEN));
            sig.SetSL(PositionGetDouble(POSITION_SL));
            sig.SetTP(PositionGetDouble(POSITION_TP));
            return true;
        }
        
        // 2. 오더 동기화 (대기 상태)
        if(OrderSelect(ticket)) {
            sig.SetLot(OrderGetDouble(ORDER_VOLUME_CURRENT));
            sig.UpdatePriceSignal(OrderGetDouble(ORDER_PRICE_OPEN));
            sig.SetSL(OrderGetDouble(ORDER_SL));
            sig.SetTP(OrderGetDouble(ORDER_TP));
            return true;
        }

        return false;
    }

    virtual double GetCurrentVolume(ulong ticket, bool isPosition) override {
        if(isPosition) {
            return PositionSelectByTicket(ticket) ? PositionGetDouble(POSITION_VOLUME) : 0;
        }
        return OrderSelect(ticket) ? OrderGetDouble(ORDER_VOLUME_CURRENT) : 0;
    }

    virtual double GetCurrentPriceOpen(ulong ticket, bool isPosition) override {
        if(isPosition) {
            return PositionSelectByTicket(ticket) ? PositionGetDouble(POSITION_PRICE_OPEN) : 0;
        }
        return OrderSelect(ticket) ? OrderGetDouble(ORDER_PRICE_OPEN) : 0;
    }

    virtual double GetCurrentProfit(ulong ticket) override {
        return PositionSelectByTicket(ticket) ? PositionGetDouble(POSITION_PROFIT) : 0;
    }
};

#endif
