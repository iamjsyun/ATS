#ifndef CXORDERMANAGER_MQH
#define CXORDERMANAGER_MQH

#include "..\..\Interfaces\IXOrderManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\ICXPriceManager.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Interfaces\IXGuard.mqh"
#include "..\..\Infra\CXMessageProvider.mqh"
#include <Trade\Trade.mqh>

/**
 * @class CXOrderManager
 * @brief 샌드박스 세션 내의 주문 실행 및 관리 담당
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
     */
    virtual bool ExecuteEntry(ICXParam* xp) override {
        if(IS_NULL(m_ctx) || IS_NULL(xp)) return false;

        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) {
            XP_LOG_ERROR(xp, "[EXEC-ENTRY] FAILED: Signal object is NULL.");
            return false;
        }

        //--- [v11.1 Service Resolution]
        IXGuard* guard = CX_GET_OBJ(m_ctx, "guard", IXGuard);
        ICXPriceManager* priceMgr = CX_GET_OBJ(m_ctx, "price_mgr", ICXPriceManager);
        if(IS_INVALID(priceMgr)) {
            XP_LOG_ERROR(xp, "[EXEC-ENTRY] FAILED: PriceManager service not found.");
            return false;
        }

        //--- [v10.7 Enhancement] Exhaustive Validation Logging
        if(IS_VALID(guard)) {
            bool vMagic = guard.ValidateMagic(sig.GetMagic());
            bool vSid   = guard.ValidateSID(sig.GetSid());
            bool vLot   = guard.ValidateLot(sig.GetSymbol(), sig.GetLot());
            bool vPrice = guard.ValidatePrice(sig.GetSymbol(), sig.GetPriceSignal());

            if(!vMagic || !vSid || !vLot || !vPrice) {
                string reason = StringFormat("Magic:%s, SID:%s, Lot:%s, Price:%s", 
                                             vMagic?"OK":"FAIL", vSid?"OK":"FAIL", vLot?"OK":"FAIL", vPrice?"OK":"FAIL");
                
                string err = StringFormat("[EXEC-ENTRY-FAIL] GUARD DENIED (%s). Symbol:%s, Lot:%.2f, Price:%.5f, Magic:%I64u", 
                                          reason, sig.GetSymbol(), sig.GetLot(), sig.GetPriceSignal(), sig.GetMagic());
                
                XP_LOG_ERROR(xp, err);
                xp.SetString(err); 
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
                return false;
            }
        }

        //--- [v11.0 Lot Validation]
        double lot = sig.GetLot();
        if(lot <= 0 || lot > 50) {
            string lotErr = StringFormat("[EXEC-ENTRY-FAIL] INVALID LOT SIZE: %.2f (Min: 0.01, Max: 50.00). SID:%s", lot, m_sid);
            XP_LOG_ERROR(xp, lotErr);
            xp.SetString(lotErr);
            CXMessageProvider::UpdateStatus(sig, XE_ERROR, lotErr);
            return false;
        }

        m_sid = sig.GetSid();
        m_trade.SetExpertMagicNumber((ulong)sig.GetMagic());

        //--- 주문 타입 및 방향 결정
        ENUM_ORDER_TYPE order_type;
        if(sig.GetType() == ORDER_MARKET) {
            order_type = (sig.GetDir() == CX_DIR_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        } else {
            order_type = (sig.GetDir() == CX_DIR_BUY) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
        }

        //--- [v11.1 SSOC Calculation] Centralized via PriceManager
        string symbol = sig.GetSymbol();
        int dir = sig.GetDir();
        double marketPrice = priceMgr.GetMarketPrice(symbol, dir);

        //--- 1. Execution Price Calculation (For Pending Orders)
        double execPrice = priceMgr.CalculateExecPrice(xp, symbol, dir, sig.GetType(), sig.GetLimitOffset());

        //--- 2. SL/TP Point-to-Price Calculation (BasePrice 기반)
        double basePrice = (sig.GetType() == ORDER_MARKET) ? marketPrice : execPrice;
        double finalSL = priceMgr.CalculateSL(xp, symbol, dir, basePrice, sig.GetSL());
        double finalTP = priceMgr.CalculateTP(xp, symbol, dir, basePrice, sig.GetTP());

        //--- [v10.10 Enhancement] Pre-flight StopLevel Validation
        if(IS_VALID(guard)) {
            if(!guard.ValidateStopLevel(sig.GetSymbol(), marketPrice, finalSL) || !guard.ValidateStopLevel(sig.GetSymbol(), marketPrice, finalTP)) {
                string err = StringFormat("[EXEC-ENTRY] INVALID STOPS (Market-Based). Req:[Mkt:%.5f, SL:%.5f, TP:%.5f], Sym:%s", 
                                          marketPrice, finalSL, finalTP, sig.GetSymbol());
                XP_LOG_ERROR(xp, err);
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, err);
                return false;
            }
        }

        //-- [v10.31] Comprehensive Execution Logging (Standard v10.4)
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double dir_sign = (dir == CX_DIR_BUY) ? 1.0 : -1.0;
        double teLimitPts = sig.GetTELimit();
        double teLimitPrice = NormalizeDouble(marketPrice - (teLimitPts * point * dir_sign), (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
        
        string entryLog = StringFormat("[EXEC-ENTRY] Sending Order: [Sym:%s, Type:%s, Lot:%.2f, Price:%.5f, SL:%.5f, TP:%.5f, Mkt:%.5f, TELimPts:%.0f, TELimP:%.5f, TESta:%.0f, TESte:%.0f, SID:%s]", 
                                       sig.GetSymbol(), EnumToString(order_type), sig.GetLot(), execPrice, finalSL, finalTP, 
                                       marketPrice, teLimitPts, teLimitPrice, sig.GetTEStart(), sig.GetTEStep(), m_sid);
        XP_LOG_INFO(xp, entryLog);

        bool order_result = false;
        
        if(sig.GetType() == ORDER_MARKET) {
            if(sig.GetDir() == CX_DIR_BUY) {
                order_result = m_trade.Buy(sig.GetLot(), sig.GetSymbol(), marketPrice, finalSL, finalTP, m_sid);
            } else {
                order_result = m_trade.Sell(sig.GetLot(), sig.GetSymbol(), marketPrice, finalSL, finalTP, m_sid);
            }
        } else {
            order_result = m_trade.OrderOpen(sig.GetSymbol(), order_type, sig.GetLot(), 0.0, execPrice, finalSL, finalTP, ORDER_TIME_GTC, 0, m_sid);
        }

        if(!order_result) {
            string retMsg = m_trade.ResultRetcodeDescription();
            uint retCode = m_trade.ResultRetcode();
            int sysErr = GetLastError();
            string typeStr = EnumToString(order_type);
            
            // [v11.1 Extended Logging] Log ALL raw parameters on failure
            string rawParams = StringFormat("RAW:[Act:%d, Sym:%s, Vol:%.2f, P:%.5f, SL:%.5f, TP:%.5f, Type:%d, Fill:%d, Time:%d, Exp:%d, Msg:%s, Mag:%I64u]",
                                            (int)order_type, symbol, lot, execPrice, finalSL, finalTP, 
                                            (int)order_type, (int)m_trade.RequestTypeFilling(), (int)m_trade.RequestTypeTime(), 
                                            (int)m_trade.RequestExpiration(), m_sid, (ulong)sig.GetMagic());

            string err_msg = StringFormat("[EXEC-ENTRY-FAIL] Broker Code:%u(%s), SysErr:%d. %s", 
                                          (uint)retCode, retMsg, (int)sysErr, rawParams);
            
            XP_LOG_ERROR(xp, err_msg);
            xp.SetString(err_msg); //-- [v10.22] Propagate error detail to session
            CXMessageProvider::UpdateStatus(sig, XE_ERROR, err_msg);
            ResetLastError();
            return false;
        }

        m_ticket = m_trade.ResultOrder();
        
        //-- [v11.0 Rule 10] Physical Asset Cross-Verification
        if(OrderSelect(m_ticket)) {
            ulong  actualMagic   = OrderGetInteger(ORDER_MAGIC);
            string actualComment = OrderGetString(ORDER_COMMENT);
            
            // 검증 조건 상세 로그 기록
            string vLog = StringFormat("[EXEC-VERIFY] Ticket:%I64u Found. Checking Integrity: [ReqMagic:%I64u == ActMagic:%I64u], [ReqSID:%s == ActComment:%s]", 
                                       m_ticket, (ulong)sig.GetMagic(), actualMagic, m_sid, actualComment);
            XP_LOG_INFO(xp, vLog);

            if(actualMagic == (ulong)sig.GetMagic() && actualComment == m_sid) {
                sig.SetTicket((long)m_ticket);
                int next_status = (sig.GetType() == ORDER_MARKET) ? XE_EXECUTED : XE_PENDING_PLACED;
                string status_msg = (sig.GetType() == ORDER_MARKET) ? MSG_ENTRY_MARKET_SUCCESS : MSG_ENTRY_LIMIT_PLACED;

                CXMessageProvider::UpdateStatus(sig, next_status, status_msg);
                XP_LOG_OK(xp, StringFormat("%s (Verified Ticket:%I64u)", status_msg, m_ticket));
                return true;
            } else {
                string mismatchErr = StringFormat("[EXEC-ENTRY-FAIL] INTEGRITY MISMATCH: Ticket:%I64u exists but Magic/SID differs.", m_ticket);
                XP_LOG_ERROR(xp, mismatchErr);
                xp.SetString(mismatchErr);
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, mismatchErr);
                return false;
            }
        } else {
            string vErr = StringFormat("[EXEC-ENTRY-FAIL] VERIFY FAILED: Ticket %I64u not found in terminal after OrderOpen. Search Criteria: [Ticket:%I64u, Magic:%I64u, SID:%s]", 
                                       m_ticket, m_ticket, (ulong)sig.GetMagic(), m_sid);
            XP_LOG_ERROR(xp, vErr);
            xp.SetString(vErr); //-- [v10.22] Propagate error detail to session
            CXMessageProvider::UpdateStatus(sig, XE_ERROR, vErr);
            return false;
        }
    }

    /**
     * @brief 주문 수정 (진트레)
     */
    virtual bool ModifyOrder(ICXParam* xp, ulong ticket, double price, double sl, double tp) override {
        if(ticket == 0) return false;
        
        XP_LOG_INFO(xp, StringFormat("[ORDER-MODIFY] Sending Request: [Ticket:%I64u, Price:%.5f, SL:%.5f, TP:%.5f]", 
                                        ticket, price, sl, tp));

        if(m_trade.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0)) {
            XP_LOG_OK(xp, StringFormat("[ORDER-MODIFY] SUCCESS: Ticket %I64u Modified.", ticket));
            return true;
        }

        string retMsg = m_trade.ResultRetcodeDescription();
        uint retCode = m_trade.ResultRetcode();
        int sysErr = GetLastError();
        string err_msg = StringFormat("[ORDER-MODIFY-FAIL] Broker Code:%u(%s), SysErr:%d. Original Params: [Ticket:%I64u, Price:%.5f, SL:%.5f, TP:%.5f]", 
                                        retCode, retMsg, sysErr, ticket, price, sl, tp);
        XP_LOG_ERROR(xp, err_msg);
        if(IS_VALID(xp)) xp.SetString(err_msg);
        ResetLastError();
        return false;
    }

    virtual bool DeleteOrder(ICXParam* xp, ulong ticket) override {
        if(ticket == 0) return false;
        
        XP_LOG_INFO(xp, StringFormat("[ORDER-DELETE] Sending Request: [Ticket:%I64u]", ticket));

        // 1. 삭제 시도
        if(!m_trade.OrderDelete(ticket)) {
            string retMsg = m_trade.ResultRetcodeDescription();
            uint retCode = m_trade.ResultRetcode();
            int sysErr = GetLastError();
            
            string err_msg = StringFormat("[ORDER-DELETE-FAIL] Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                            retCode, retMsg, sysErr, ticket);
            XP_LOG_ERROR(xp, err_msg);
            if(IS_VALID(xp)) xp.SetString(err_msg);
            ResetLastError();
            return false;
        }
        
        // 2. 삭제 확인 (v10.29 Enhancement: Use a short sleep or retry if needed, but for now just select)
        if(OrderSelect(ticket)) {
            string vErr = StringFormat("[ORDER-DELETE-FAIL] VERIFY FAILED: Ticket:%I64u still exists after deletion request.", ticket);
            XP_LOG_ERROR(xp, vErr);
            if(IS_VALID(xp)) xp.SetString(vErr);
            return false;
        }
        
        XP_LOG_OK(xp, StringFormat("[ORDER-DELETE] SUCCESS: Ticket %I64u Deleted.", ticket));
        return true;
    }
};

#endif
