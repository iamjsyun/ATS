#ifndef CXORDERMANAGER_MQH
#define CXORDERMANAGER_MQH

#include "..\..\Core\Interfaces\IXOrderManager.mqh"
#include "..\..\Core\Interfaces\ICXContext.mqh"
#include "..\..\Core\Interfaces\ICXParam.mqh"
#include "..\..\Core\Interfaces\ICXPriceManager.mqh"
#include "..\..\Core\Interfaces\ICXRiskManager.mqh"
#include "..\..\Core\Interfaces\ICXSymbolManager.mqh"
#include "..\..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\..\Core\Interfaces\ICXAuditProvider.mqh"
#include "..\..\Core\Interfaces\IXGuard.mqh"
#include "..\..\Core\Defines\CXDefine.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"
#include "..\..\Shared\Logging\CXMessageProvider.mqh"
#include "..\..\Shared\Logging\CXAuditFormatter.mqh"
#include <Trade\Trade.mqh>

/**
 * @class CXOrderManager
 * @brief 주문 전송 및 관리 전담 구현체 (v13.5 UAF & Resilience Standard)
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

    virtual string GetAuditString(ICXParam* xp, string actionLabel = "") override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return "[FUNC:" + actionLabel + "] INVALID_SIGNAL";
        
        string spec = xp.GetString();
        if(spec == "") {
            string symbol = sig.GetSymbol();
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            double mkt   = SymbolInfoDouble(symbol, (sig.GetDir() == CX_DIR_BUY) ? SYMBOL_ASK : SYMBOL_BID);
            double tesp = (sig.GetTEStart() >= 1) ? mkt + (sig.GetTEStart() * point * (sig.GetDir()==CX_DIR_BUY?-1:1)) : 0.0;
            double telp = (sig.GetTELimit() >= 1) ? mkt + (sig.GetTELimit() * point * (sig.GetDir()==CX_DIR_BUY?-1:1)) : 0.0;
            spec = StringFormat("ESTART:%d, ESPRI:%.2f, ELPRI:%.2f", (int)sig.GetTEStart(), tesp, telp);
        }

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

        // 1. 오더가 아직 존재하면 정상 (대기 중)
        if(invMgr.IsOrderExists(ticket)) return;
        
        // 2. 오더가 없는데 포지션이 있으면 정상 (체결됨)
        if(invMgr.IsPositionExists(ticket)) return;

        string reason = "";
        int status = invMgr.CheckHistoryClosure(ticket, reason);

        if(status != XE_UNKNOWN) {
            IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
            CXMessageProvider::UpdateStatus(sig, status, reason);
            if(IS_VALID(repo)) repo.UpdateStatus(sig);
            XP_LOG_INFO(xp, CXAuditFormatter::Build("ORDER-MANAGER", xp, "Asset Closure Detected: " + reason));
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

        string sid = sig.GetSid();

        // [v14.40 Anti-Proliferation] Pre-flight Check:
        // Before sending order, check if an asset with this SID already exists in terminal.
        // This prevents creating multiple tickets during "Market Closed" retries or lag.
        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_VALID(invMgr)) {
            ulong existingTicket = 0;
            // Scan positions and orders for this SID
            for(int i = PositionsTotal() - 1; i >= 0; i--) {
                if(PositionSelectByTicket(PositionGetTicket(i)) && PositionGetString(POSITION_COMMENT) == sid) {
                    existingTicket = PositionGetInteger(POSITION_TICKET);
                    break;
                }
            }
            if(existingTicket == 0) {
                for(int i = OrdersTotal() - 1; i >= 0; i--) {
                    if(OrderSelect(OrderGetTicket(i)) && OrderGetString(ORDER_COMMENT) == sid) {
                        existingTicket = OrderGetInteger(ORDER_TICKET);
                        break;
                    }
                }
            }

            if(existingTicket > 0) {
                XP_LOG_WARN(xp, CXAuditFormatter::Build("EXEC-ENTRY-BIND", xp, StringFormat("Proliferation Guard: Asset found with same SID (%I64u). Binding instead of sending.", existingTicket)));
                sig.SetTicket(existingTicket);
                
                // [v14.43 Fix] Ensure DB state is updated after binding
                CXMessageProvider::UpdateStatus(sig, XE_IN_TRANSIT, "Bound to existing asset: " + (string)existingTicket);
                IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                
                return true; 
            }
        }

        // [v14.40 Throttled Retry]
        // If we recently failed with Market Closed, wait at least 60 seconds before trying again.
        string retryTimerKey = "EntryRetryTimer_" + sid;
        CObject* objTimer = m_ctx.Get(retryTimerKey);
        if(IS_VALID(objTimer)) {
            CXParam* pTimer = dynamic_cast<CXParam*>(objTimer);
            if(IS_VALID(pTimer) && (TimeCurrent() < (datetime)pTimer.GetLong())) {
                xp.SetString("WAIT_MARKET_OPEN"); // Stay in wait state
                return false;
            }
        }

        string symbol = sig.GetSymbol();
        int    dir    = sig.GetDir();
        double lot    = sig.GetLot();
        long   magic  = sig.GetMagic();
        string comment = sid;
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
        
        // [v11.10] Pre-Call Raw Parameter Audit
        string rawParams = StringFormat("Raw: [Sym:%s, Lot:%.2f, Type:%d, P:%.2f, SL:%.2f, TP:%.2f, Magic:%I64d, SID:%s]",
                                        symbol, lot, order_type, execPrice, finalSL, finalTP, magic, comment);
        xp.SetString(rawParams);
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:" + funcName);
        XP_LOG_OK(xp, auditMsg);
        Print(auditMsg);

        IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
        CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), "Calling " + funcName + "...");
        if(IS_VALID(repo)) repo.UpdateStatus(sig);

        bool success = (sig.GetType() == ORDER_MARKET) ?
            m_trade.PositionOpen(symbol, order_type, lot, execPrice, finalSL, finalTP, comment) :
            m_trade.OrderOpen(symbol, order_type, lot, 0, execPrice, finalSL, finalTP, ORDER_TIME_GTC, 0, comment);

        xp.SetString(""); // Clear for next use
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = CXAuditFormatter::Build("AUDIT-RECEPTION", xp, StringFormat("%s Result: %s (Code:%u)", funcName, success?"SUCCESS":"FAILED", retCode));
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);

        if(!success) {
            uint retCode = m_trade.ResultRetcode();
            string errDescription = m_trade.ResultRetcodeDescription();
            string err = StringFormat("%s FAIL. Code:%u(%s)", funcName, retCode, errDescription);

            // [v14.32 Resilience] Market Closed (10018) is a transient state, not a fatal error.
            if(retCode == 10018) {
                XP_LOG_WARN(xp, CXAuditFormatter::Build("EXEC-ENTRY-WAIT", xp, "Market Closed. Throttling retry for 60s."));
                CXMessageProvider::UpdateStatus(sig, sig.GetStatus(), "Waiting: Market Closed");
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                
                // Set throttle timer
                CXParam* pNewTimer = new CXParam();
                pNewTimer.SetLong((long)(TimeCurrent() + 60));
                m_ctx.Set(retryTimerKey, pNewTimer);

                xp.SetString("WAIT_MARKET_OPEN"); // Pass signal to task
                return false;
            }

            XP_LOG_ERROR(xp, CXAuditFormatter::Build("EXEC-ENTRY-FAIL", xp, err));
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
        
        // [v11.10] Pre-Call Raw Parameter Audit
        string rawParams = StringFormat("Raw: [Ticket:%I64u, SID:%s]", ticket, sig.GetSid());
        xp.SetString(rawParams);
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:" + funcName);
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = invMgr.IsPositionExists(ticket) ? m_trade.PositionClose(ticket) : m_trade.OrderDelete(ticket);
        
        xp.SetString(""); // Clear for next use
        PrintFormat("[AUDIT-RECEPTION] %s Result: %s (Code:%u)", funcName, success?"SUCCESS":"FAILED", m_trade.ResultRetcode());
        return success;
    }

    virtual bool ModifyOrder(ICXParam* xp, ulong ticket, double price, double sl, double tp) override {
        // [v11.10] Pre-Call Raw Parameter Audit
        string rawParams = StringFormat("Raw: [Ticket:%I64u, P:%.2f, SL:%.2f, TP:%.2f]", ticket, price, sl, tp);
        xp.SetString(rawParams);
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:OrderModify");
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = m_trade.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0);
        
        xp.SetString(""); // Clear for next use
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = CXAuditFormatter::Build("AUDIT-RECEPTION", xp, StringFormat("OrderModify Result: %s (Code:%u)", success?"SUCCESS":"FAILED", retCode));
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);
        
        if(!success && retCode == 10018) {
             XP_LOG_WARN(xp, CXAuditFormatter::Build("EXEC-MOD-WAIT", xp, "Market Closed during modification."));
             xp.SetString("WAIT_MARKET_OPEN");
        }
        
        return success;
    }

    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) override {
        // [v11.10] Pre-Call Raw Parameter Audit
        string rawParams = StringFormat("Raw: [Ticket:%I64u, SL:%.2f, TP:%.2f]", ticket, sl, tp);
        xp.SetString(rawParams);
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:PositionModify");
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = m_trade.PositionModify(ticket, sl, tp);
        
        xp.SetString(""); // Clear for next use
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = CXAuditFormatter::Build("AUDIT-RECEPTION", xp, StringFormat("PositionModify Result: %s (Code:%u)", success?"SUCCESS":"FAILED", retCode));
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);

        if(!success && retCode == 10018) {
             XP_LOG_WARN(xp, CXAuditFormatter::Build("EXEC-POS-WAIT", xp, "Market Closed during position modification."));
             xp.SetString("WAIT_MARKET_OPEN");
        }
        
        return success;
    }

    virtual bool DeleteOrder(ICXParam* xp, ulong ticket) override {
        // [v11.10] Pre-Call Raw Parameter Audit
        string rawParams = StringFormat("Raw: [Ticket:%I64u]", ticket);
        xp.SetString(rawParams);
        string auditMsg = GetAuditString(xp, "AUDIT-CALL:OrderDelete");
        XP_LOG_INFO(xp, auditMsg);
        Print(auditMsg);
        
        bool success = m_trade.OrderDelete(ticket);
        
        xp.SetString(""); // Clear for next use
        uint retCode = m_trade.ResultRetcode();
        string receptionMsg = CXAuditFormatter::Build("AUDIT-RECEPTION", xp, StringFormat("OrderDelete Result: %s (Code:%u)", success?"SUCCESS":"FAILED", retCode));
        XP_LOG_INFO(xp, receptionMsg);
        Print(receptionMsg);
        
        return success;
    }
};

#endif
