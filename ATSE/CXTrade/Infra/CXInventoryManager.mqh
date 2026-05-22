#ifndef CXINVENTORYMANAGER_MQH
#define CXINVENTORYMANAGER_MQH

#include "..\Interfaces\ICXInventoryManager.mqh"
#include "..\Interfaces\CXDefine.mqh"
#include "..\Infra\CXAuditFormatter.mqh"

/**
 * @class CXInventoryManager
 * @brief 터미널 실물 자산 상태 확인 및 동기화 구현체 (SSOC: Inventory)
 */
class CXInventoryManager : public ICXInventoryManager {
public:
    CXInventoryManager() {}
    virtual ~CXInventoryManager() {}

    /**
     * @brief [v13.4 Audit] 인벤토리 요약 감사 문자열 생성
     */
    virtual string GetAuditString(ICXParam* xp, string actionLabel = "") override {
        int posTotal = PositionsTotal();
        int ordTotal = OrdersTotal();
        string spec = StringFormat("PosCount:%d, OrdCount:%d", posTotal, ordTotal);
        return CXAuditFormatter::Build(actionLabel, xp, spec);
    }

    virtual bool IsPositionExists(ulong ticket) override {
        if(ticket <= 0) return false;
        return PositionSelectByTicket(ticket);
    }

    virtual bool IsOrderExists(ulong ticket) override {
        if(ticket <= 0) return false;
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

    virtual double GetCurrentSL(ulong ticket) override {
        if(PositionSelectByTicket(ticket)) return PositionGetDouble(POSITION_SL);
        if(OrderSelect(ticket)) return OrderGetDouble(ORDER_SL);
        return 0;
    }

    virtual double GetCurrentTP(ulong ticket) override {
        if(PositionSelectByTicket(ticket)) return PositionGetDouble(POSITION_TP);
        if(OrderSelect(ticket)) return OrderGetDouble(ORDER_TP);
        return 0;
    }

    virtual double GetCurrentProfit(ulong ticket) override {
        return PositionSelectByTicket(ticket) ? PositionGetDouble(POSITION_PROFIT) : 0;
    }

    /**
     * @brief 히스토리를 추적하여 청산 사유 및 최종 상태 반환
     */
    virtual int CheckHistoryClosure(ulong ticket, string &reason) override {
        if(ticket <= 0) {
            reason = "Invalid Ticket (0)";
            return XE_UNKNOWN;
        }

        if(HistorySelect(0, TimeCurrent())) {
            int total = HistoryDealsTotal();
            for(int i = total - 1; i >= 0; i--) {
                ulong dealTicket = HistoryDealGetTicket(i);
                if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == ticket &&
                   HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
                   
                    reason = HistoryDealGetString(dealTicket, DEAL_COMMENT);
                    
                    if(StringFind(reason, "[sl]") >= 0 || StringFind(reason, "sl") >= 0) {
                        reason = "Closed by SL (" + reason + ")";
                        return XE_CLOSED_SL;
                    } 
                    if(StringFind(reason, "[tp]") >= 0 || StringFind(reason, "tp") >= 0) {
                        reason = "Closed by TP (" + reason + ")";
                        return XE_CLOSED_TP;
                    }
                    
                    reason = "Closed by Broker/Manual (" + reason + ")";
                    return XE_CLOSED_SIGNAL;
                }
            }

            // [v11.6] 만약 오더 히스토리에서 취소된 내역이 있는지 추가 확인
            int totalOrders = HistoryOrdersTotal();
            for(int i = totalOrders - 1; i >= 0; i--) {
                ulong histTicket = HistoryOrderGetTicket(i);
                if(histTicket == ticket) {
                    ENUM_ORDER_STATE state = (ENUM_ORDER_STATE)HistoryOrderGetInteger(histTicket, ORDER_STATE);
                    if(state == ORDER_STATE_CANCELED) {
                        reason = "Pending Order Canceled by User/Broker";
                        return XE_CLOSED_SIGNAL;
                    }
                    if(state == ORDER_STATE_EXPIRED) {
                        reason = "Pending Order Expired";
                        return XE_CLOSED_SIGNAL;
                    }
                }
            }
        }
        
        reason = "Asset Not Found in Terminal/History";
        return XE_UNKNOWN;
    }
};

#endif
