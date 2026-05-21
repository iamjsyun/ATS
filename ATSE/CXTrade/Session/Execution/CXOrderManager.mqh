#ifndef CXORDERMANAGER_MQH
#define CXORDERMANAGER_MQH

#include "..\..\Interfaces\IXOrderManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\ICXPriceManager.mqh"
#include "..\..\Interfaces\ICXRiskManager.mqh"
#include "..\..\Interfaces\ICXSymbolManager.mqh"
#include "..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\Interfaces\IXGuard.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Infra\CXMessageProvider.mqh"
#include <Trade\Trade.mqh>

/**
 * @class CXOrderManager
 * @brief 주문 전송 및 관리 전담 구현체 (v11.3 SSOC Alignment)
 */
class CXOrderManager : public IXOrderManager {
private:
    ulong           m_ticket;
    string          m_sid;
    CTrade          m_trade;
    ICXContext*     m_ctx;

public:
    CXOrderManager(ICXContext* ctx) : m_ctx(ctx), m_ticket(0), m_sid("") {}
    virtual ~CXOrderManager() override {}

    virtual void SetMagic(ulong magic) override { m_trade.SetExpertMagicNumber(magic); }

    /**
     * @brief 진입 주문 실행 (xa_entry 기반)
     * @details [v11.5 Alignment] L-P 단계를 거쳐 계산/저장된 가격 정보를 기반으로 물리적 주문만 송신 (SRP)
     */
    virtual bool ExecuteEntry(ICXParam* xp) override {
        if(IS_NULL(m_ctx) || IS_NULL(xp)) return false;

        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return false;

        //--- [v11.5 SRP] 모든 검증 및 계산은 이전 Task(L-P)에서 완료됨을 전제로 함
        string symbol = sig.GetSymbol();
        int    dir    = sig.GetDir();
        double lot    = sig.GetLot();
        long   magic  = sig.GetMagic();
        string comment = sig.GetSid();
        m_sid = comment;

        //--- 미리 계산된 가격 정보 추출 (L-stage 결과물)
        double execPrice = sig.GetPriceOpen();
        double finalSL   = sig.GetPriceSL();
        double finalTP   = sig.GetPriceTP();

        //--- 주문 타입 결정
        ENUM_ORDER_TYPE order_type;
        if(sig.GetType() == ORDER_MARKET) {
            order_type = (dir == CX_DIR_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        } else {
            order_type = (dir == CX_DIR_BUY) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
        }

        XP_LOG_TRACE(xp, StringFormat("[EXEC-ENTRY] Physical Request: [Sym:%s, Type:%d, Lot:%.2f, P:%.5f, SL:%.5f, TP:%.5f]", 
                                      symbol, (int)order_type, lot, execPrice, finalSL, finalTP));

        //--- CTrade 설정 및 송신
        m_trade.SetExpertMagicNumber(magic);

        bool success = false;
        if(sig.GetType() == ORDER_MARKET) {
            success = m_trade.PositionOpen(symbol, order_type, lot, execPrice, finalSL, finalTP, comment);
        } else {
            success = m_trade.OrderOpen(symbol, order_type, lot, 0, execPrice, finalSL, finalTP, ORDER_TIME_GTC, 0, comment);
        }

        //--- 결과 처리
        uint retCode = m_trade.ResultRetcode();
        if(!success) {
            string err = StringFormat("[EXEC-ENTRY-FAIL] Broker Code:%u(%s), SysErr:%d. SID:%s", 
                                      retCode, m_trade.ResultRetcodeDescription(), GetLastError(), m_sid);
            XP_LOG_ERROR(xp, err);
            // 에러 시 xp에 메시지 전송 (시퀀스 에러 처리용)
            xp.SetString(err);
            return false;
        }

        ulong ticket = (sig.GetType() == ORDER_MARKET) ? m_trade.ResultDeal() : m_trade.ResultOrder();
        if(ticket == 0) ticket = m_trade.ResultOrder(); 
        
        sig.SetTicket((long)ticket);
        XP_LOG_OK(xp, StringFormat("[EXEC-ENTRY] SUCCESS: Ticket %I64u Opened. Code:%u", ticket, retCode));
        
        return true;
    }

    /**
     * @brief 청산 주문 실행 (xa_exit 기반)
     */
    virtual bool ExecuteExit(ICXParam* xp) override {
        if(IS_NULL(m_ctx) || IS_NULL(xp)) return false;

        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return false;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) return false;

        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_INVALID(invMgr)) return false;

        m_sid = sig.GetSid();
        XP_LOG_INFO(xp, StringFormat("[EXEC-EXIT] Requesting Close for Ticket:%I64u, SID:%s", ticket, m_sid));

        bool success = false;
        if(invMgr.IsPositionExists(ticket)) {
            success = m_trade.PositionClose(ticket);
        } else if(invMgr.IsOrderExists(ticket)) {
            success = m_trade.OrderDelete(ticket);
        } else {
            XP_LOG_WARN(xp, StringFormat("[EXEC-EXIT] Ticket %I64u not found in terminal. Marked as phantom.", ticket));
            return true; 
        }

        if(!success) {
            string err = StringFormat("[EXEC-EXIT-FAIL] Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                      m_trade.ResultRetcodeDescription(), m_trade.ResultRetcode(), GetLastError(), ticket);
            XP_LOG_ERROR(xp, err);
            if(IS_VALID(xp)) xp.SetString(err); //-- [v11.5] Error propagation
            return false;
        }

        XP_LOG_OK(xp, StringFormat("[EXEC-EXIT] SUCCESS: Ticket %I64u Close Request Sent.", ticket));
        return true;
    }

    virtual bool ModifyOrder(ICXParam* xp, ulong ticket, double price, double sl, double tp) override {
        if(ticket == 0) return false;
        
        //--- [v11.2 Enhancement] Pre-flight StopLevel Validation for Modification
        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        IXGuard*             guard  = CX_GET_OBJ(m_ctx, "guard", IXGuard);
        
        if(IS_VALID(invMgr) && IS_VALID(guard)) {
            string symbol = "";
            if(OrderSelect(ticket)) symbol = OrderGetString(ORDER_SYMBOL);
            
            if(symbol != "") {
                if(!guard.ValidateStopLevel(symbol, price, sl)) {
                    XP_LOG_WARN(xp, StringFormat("[ORDER-MODIFY] SL too close (P:%.5f, SL:%.5f). Resetting SL to 0.", price, sl));
                    sl = 0;
                }
                if(!guard.ValidateStopLevel(symbol, price, tp)) {
                    XP_LOG_WARN(xp, StringFormat("[ORDER-MODIFY] TP too close (P:%.5f, TP:%.5f). Resetting TP to 0.", price, tp));
                    tp = 0;
                }
            }
        }

        XP_LOG_INFO(xp, StringFormat("[ORDER-MODIFY] Sending Request: [Ticket:%I64u, Price:%.5f, SL:%.5f, TP:%.5f]", 
                                        ticket, price, sl, tp));
        
        if(!m_trade.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0)) {
            string vErr = StringFormat("[ORDER-MODIFY-FAIL] Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                       m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription(), GetLastError(), ticket);
            XP_LOG_ERROR(xp, vErr);
            if(IS_VALID(xp)) xp.SetString(vErr);
            return false;
        }
        
        XP_LOG_OK(xp, StringFormat("[ORDER-MODIFY] SUCCESS: Ticket %I64u Modified.", ticket));
        return true;
    }

    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) override {
        if(ticket == 0) return false;
        
        //--- [v11.2 StopLevel Validation]
        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        IXGuard*             guard  = CX_GET_OBJ(m_ctx, "guard", IXGuard);
        ICXPriceManager*     priceMgr = CX_GET_OBJ(m_ctx, "price_mgr", ICXPriceManager);

        if(IS_VALID(invMgr) && IS_VALID(guard) && IS_VALID(priceMgr) && PositionSelectByTicket(ticket)) {
            string symbol = PositionGetString(POSITION_SYMBOL);
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int dir = (posType == POSITION_TYPE_BUY) ? CX_DIR_BUY : CX_DIR_SELL;
            
            //--- [v11.5 Alignment] For active positions, StopLevel is validated against liquidation price (Bid for Buy, Ask for Sell)
            double vBase = priceMgr.GetLiquidationPrice(symbol, dir);
            
            if(!guard.ValidateStopLevel(symbol, vBase, sl)) {
                XP_LOG_WARN(xp, StringFormat("[POS-MODIFY] SL too close (Base:%.5f, SL:%.5f). Resetting SL to 0.", vBase, sl));
                sl = 0;
            }
            if(!guard.ValidateStopLevel(symbol, vBase, tp)) {
                XP_LOG_WARN(xp, StringFormat("[POS-MODIFY] TP too close (Base:%.5f, TP:%.5f). Resetting TP to 0.", vBase, tp));
                tp = 0;
            }
        }

        XP_LOG_INFO(xp, StringFormat("[POS-MODIFY] Sending Request: [Ticket:%I64u, SL:%.5f, TP:%.5f]", ticket, sl, tp));
        
        if(!m_trade.PositionModify(ticket, sl, tp)) {
            string vErr = StringFormat("[POS-MODIFY-FAIL] Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                       m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription(), GetLastError(), ticket);
            XP_LOG_ERROR(xp, vErr);
            if(IS_VALID(xp)) xp.SetString(vErr);
            return false;
        }
        
        XP_LOG_OK(xp, StringFormat("[POS-MODIFY] SUCCESS: Ticket %I64u Modified.", ticket));
        return true;
    }

    virtual bool DeleteOrder(ICXParam* xp, ulong ticket) override {
        if(ticket == 0) return false;
        
        XP_LOG_INFO(xp, StringFormat("[ORDER-DELETE] Sending Request: [Ticket:%I64u]", ticket));
        
        if(!m_trade.OrderDelete(ticket)) {
            string vErr = StringFormat("[ORDER-DELETE-FAIL] Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                       m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription(), GetLastError(), ticket);
            XP_LOG_ERROR(xp, vErr);
            if(IS_VALID(xp)) xp.SetString(vErr);
            return false;
        }
        
        XP_LOG_OK(xp, StringFormat("[ORDER-DELETE] SUCCESS: Ticket %I64u Deleted.", ticket));
        return true;
    }
};

#endif
