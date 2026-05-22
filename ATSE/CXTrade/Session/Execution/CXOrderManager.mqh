#ifndef CXORDERMANAGER_MQH
#define CXORDERMANAGER_MQH

#include "..\..\Interfaces\IXOrderManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\ICXPriceManager.mqh"
#include "..\..\Interfaces\ICXRiskManager.mqh"
#include "..\..\Interfaces\ICXSymbolManager.mqh"
#include "..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\Interfaces\ICXAuditProvider.mqh"
#include "..\..\Interfaces\IXGuard.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Infra\CXMessageProvider.mqh"
#include "..\..\Infra\CXAuditFormatter.mqh"
#include <Trade\Trade.mqh>

/**
 * @class CXOrderManager
 * @brief 주문 전송 및 관리 전담 구현체 (v13.4 UAF Standard)
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

    /**
     * @brief [v13.4 UAF] 통합 감사 로그 문자열 생성
     */
    virtual string GetAuditString(ICXParam* xp, string actionLabel = "") override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return "[" + actionLabel + "] INVALID_SIGNAL";
        
        string symbol = sig.GetSymbol();
        ICXSymbolManager* symMgr = CX_GET_OBJ(m_ctx, "sym_mgr", ICXSymbolManager);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(symbol) : SymbolInfoDouble(symbol, SYMBOL_POINT);
        double mkt   = SymbolInfoDouble(symbol, (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_ASK : SYMBOL_BID);

        string spec = StringFormat("TEPts:[%d,%d,%d], TEPri:[%.5f,%.5f,%.5f]",
                                    sig.GetTEStart(), sig.GetTEStep(), sig.GetTELimit(),
                                    mkt - (sig.GetTEStart() * point * (sig.GetDir()==CX_DIR_BUY?1:-1)),
                                    sig.GetTEStep() * point,
                                    mkt - (sig.GetTELimit() * point * (sig.GetDir()==CX_DIR_BUY?1:-1)));

        return CXAuditFormatter::Build(actionLabel, xp, spec);
    }

    virtual void SetMagic(ulong magic) override { m_trade.SetExpertMagicNumber(magic); }

    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(m_ctx) || IS_INVALID(xp)) return;
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return;

        ulong ticket = sig.GetTicket();
        if(ticket == 0) return;

        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_INVALID(invMgr)) return;

        if(invMgr.IsOrderExists(ticket)) return;

        string reason = "";
        int status = invMgr.CheckHistoryClosure(ticket, reason);

        if(status != XE_UNKNOWN) {
            IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
            CXMessageProvider::UpdateStatus(sig, status, reason);
            if(IS_VALID(repo)) repo.UpdateStatus(sig);
            XP_LOG_INFO(xp, StringFormat("[ORDER-MANAGER] Pending Order closed. Reason: %s", reason));
            return;
        }

        string retryKey = StringFormat("OrdHistRetry_%I64u", ticket);
        int retryCount = 0;
        CObject* obj = m_ctx.Get(retryKey);
        if(IS_VALID(obj)) {
            CXParam* pOld = dynamic_cast<CXParam*>(obj);
            if(IS_VALID(pOld)) retryCount = pOld.GetInt();
        }

        if(retryCount < 5) {
            CXParam* pRetry = new CXParam();
            pRetry.SetInt(retryCount + 1);
            m_ctx.Set(retryKey, pRetry);
            return;
        }

        IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, "Order History Timeout");
        if(IS_VALID(repo)) repo.UpdateStatus(sig);
    }

    virtual bool ExecuteEntry(ICXParam* xp) override {
        if(IS_NULL(m_ctx) || IS_NULL(xp)) return false;
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return false;

        string symbol = sig.GetSymbol();
        int    dir    = sig.GetDir();
        double lot    = sig.GetLot();
        long   magic  = sig.GetMagic();
        string comment = sig.GetSid();
        m_sid = comment;

        double execPrice = sig.GetPriceOpen();
        double finalSL   = sig.GetPriceSL();
        double finalTP   = sig.GetPriceTP();
        
        ENUM_ORDER_TYPE order_type = (sig.GetType() == ORDER_MARKET) ? 
                                     (dir == CX_DIR_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL) : 
                                     (dir == CX_DIR_BUY ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT);

        m_trade.SetExpertMagicNumber(magic);
        ICXSymbolManager* symMgr = CX_GET_OBJ(m_ctx, "sym_mgr", ICXSymbolManager);
        double point = IS_VALID(symMgr) ? symMgr.GetPoint(symbol) : SymbolInfoDouble(symbol, SYMBOL_POINT);

        double currentMkt = SymbolInfoDouble(symbol, (dir == CX_DIR_BUY) ? SYMBOL_ASK : SYMBOL_BID);
        int stopsLevel = IS_VALID(symMgr) ? symMgr.GetStopsLevel(symbol) : (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
        double minDistance = (stopsLevel + 1) * point;
        
        if(sig.GetType() != ORDER_MARKET) {
            if(dir == CX_DIR_BUY && execPrice > currentMkt - minDistance) execPrice = currentMkt - minDistance;
            else if (dir == CX_DIR_SELL && execPrice < currentMkt + minDistance) execPrice = currentMkt + minDistance;
        }

        string funcName = (sig.GetType() == ORDER_MARKET) ? "PositionOpen" : "OrderOpen";
        
        if(sig.GetType() != ORDER_MARKET && sig.GetTELimit() > 0) {
            double distPts = MathAbs(currentMkt - execPrice) / point;
            if(distPts > (double)sig.GetTELimit() + 2.0) {
                string err = StringFormat("TE-LIMIT VIOLATION: Dist %.1f > Limit %d", distPts, sig.GetTELimit());
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
                IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                return false;
            }
        }

        string auditMsg = GetAuditString(xp, "AUDIT-CALL:" + funcName);
        XP_LOG_OK(xp, auditMsg);
        Print(auditMsg);

        IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
        CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), "Calling " + funcName + "...");
        if(IS_VALID(repo)) repo.UpdateStatus(sig);

        bool success = (sig.GetType() == ORDER_MARKET) ?
            m_trade.PositionOpen(symbol, order_type, lot, execPrice, finalSL, finalTP, comment) :
            m_trade.OrderOpen(symbol, order_type, lot, 0, execPrice, finalSL, finalTP, ORDER_TIME_GTC, 0, comment);

        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = StringFormat("[AUDIT-RECEPTION] %s Result: %s (Code:%u)", funcName, success?"SUCCESS":"FAILED", retCode);
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);

        if(!success) {
            string err = StringFormat("[EXEC-ENTRY-FAIL] %s. Code:%u(%s)", funcName, retCode, m_trade.ResultRetcodeDescription());
            XP_LOG_ERROR(xp, err);
            CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
            if(IS_VALID(repo)) repo.UpdateStatus(sig);
            return false;
        }

        ulong ticket = (sig.GetType() == ORDER_MARKET) ? m_trade.ResultDeal() : m_trade.ResultOrder();
        if(ticket == 0) ticket = m_trade.ResultOrder();
        sig.SetTicket(ticket);
        CXMessageProvider::UpdateStatus(sig, XE_IN_TRANSIT, "Order Placed: " + (string)ticket);
        if(IS_VALID(repo)) repo.UpdateStatus(sig);

        return true;
    }

    virtual bool ExecuteExit(ICXParam* xp) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return false;
        ulong ticket = (ulong)sig.GetTicket();
        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_INVALID(invMgr) || ticket <= 0) return false;

        string funcName = invMgr.IsPositionExists(ticket) ? "PositionClose" : "OrderDelete";
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:" + funcName);
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = invMgr.IsPositionExists(ticket) ? m_trade.PositionClose(ticket) : m_trade.OrderDelete(ticket);
        
        PrintFormat("[AUDIT-RECEPTION] %s Result: %s (Code:%u)", funcName, success?"SUCCESS":"FAILED", m_trade.ResultRetcode());
        return success;
    }

    virtual bool ModifyOrder(ICXParam* xp, ulong ticket, double price, double sl, double tp) override {
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:OrderModify");
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = m_trade.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0);
        
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = StringFormat("[AUDIT-RECEPTION] OrderModify Result: %s (Code:%u)", success?"SUCCESS":"FAILED", retCode);
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);
        
        return success;
    }

    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) override {
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:PositionModify");
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = m_trade.PositionModify(ticket, sl, tp);
        
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = StringFormat("[AUDIT-RECEPTION] PositionModify Result: %s (Code:%u)", success?"SUCCESS":"FAILED", retCode);
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);
        
        return success;
    }

    virtual bool DeleteOrder(ICXParam* xp, ulong ticket) override {
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:OrderDelete");
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = m_trade.OrderDelete(ticket);
        
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = StringFormat("[AUDIT-RECEPTION] OrderDelete Result: %s (Code:%u)", success?"SUCCESS":"FAILED", retCode);
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);
        
        return success;
    }
};

#endif
