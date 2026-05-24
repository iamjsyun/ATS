#ifndef CXEXITMANAGER_MQH
#define CXEXITMANAGER_MQH

#include "..\..\Interfaces\IXExitManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Infra\CXAuditFormatter.mqh"
#include <Trade\Trade.mqh>

/**
 * @class CXExitManager
 * @brief 샌드박스 세션 내의 청산 및 주문 취소 담당 (3-Layer Guard)
 */
class CXExitManager : public IXExitManager {
private:
    ulong           m_magic;
    ICXContext*     m_ctx;
    CTrade          m_trade;

public:
    CXExitManager(ICXContext* ctx) : m_ctx(ctx), m_magic(0) {}
    virtual ~CXExitManager() override {}

    virtual void SetMagic(ulong magic) override { m_magic = magic; m_trade.SetExpertMagicNumber(magic); }

    /**
     * @brief Layer 1: 티켓 기반 정밀 청산 및 사후 검증
     */
    virtual bool CloseByTicket(ICXParam* xp, ICXSignal* sig) override {
        if(IS_INVALID(sig)) return false;
        ulong ticket = (ulong)sig.GetTicket();
        string sid = sig.GetSid();
        if(ticket <= 0) return true;
        
        bool res = false;
        if(PositionSelectByTicket(ticket)) {
            // [v14.0 Strict SID/Ticket Verification]
            if(PositionGetString(POSITION_COMMENT) != sid) {
                string mismatchErr = StringFormat("SID Mismatch. Ticket:%I64u belongs to %s, not %s", 
                                              ticket, PositionGetString(POSITION_COMMENT), sid);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("POS-CLOSE-ABORT", xp, mismatchErr));
                return false;
            }

            XP_LOG_INFO(xp, CXAuditFormatter::Build("POS-CLOSE-SEND", xp, StringFormat("Requesting Close: [Ticket:%I64u]", ticket)));
            if(m_trade.PositionClose(ticket)) {
                // 재확인: 포지션 소멸 확인
                if(!PositionSelectByTicket(ticket)) {
                    XP_LOG_OK(xp, CXAuditFormatter::Build("POS-CLOSE-SUCCESS", xp, StringFormat("Ticket %I64u Closed.", ticket)));
                    res = true;
                }
            }
            
            if(!res) {
                string retMsg = m_trade.ResultRetcodeDescription();
                uint retCode = m_trade.ResultRetcode();
                int sysErr = GetLastError();
                string err_msg = StringFormat("Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                                retCode, retMsg, sysErr, ticket);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("POS-CLOSE-FAIL", xp, err_msg));
                if(IS_VALID(xp)) xp.SetString("[POS-CLOSE-FAIL] " + err_msg);
                ResetLastError();
            }
        }
        else if(OrderSelect(ticket)) {
            // [v14.0 Strict SID/Ticket Verification]
            if(OrderGetString(ORDER_COMMENT) != sid) {
                string mismatchErr = StringFormat("SID Mismatch. Ticket:%I64u belongs to %s, not %s", 
                                              ticket, OrderGetString(ORDER_COMMENT), sid);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("ORDER-DELETE-ABORT", xp, mismatchErr));
                return false;
            }

            XP_LOG_INFO(xp, CXAuditFormatter::Build("ORDER-DELETE-SEND", xp, StringFormat("Requesting Delete: [Ticket:%I64u]", ticket)));
            if(m_trade.OrderDelete(ticket)) {
                // 재확인: 주문 소멸 확인
                if(!OrderSelect(ticket)) {
                    XP_LOG_OK(xp, CXAuditFormatter::Build("ORDER-DELETE-SUCCESS", xp, StringFormat("Ticket %I64u Deleted.", ticket)));
                    res = true;
                }
            }
            
            if(!res) {
                string retMsg = m_trade.ResultRetcodeDescription();
                uint retCode = m_trade.ResultRetcode();
                int sysErr = GetLastError();
                string err_msg = StringFormat("Broker Code:%u(%s), SysErr:%d. Ticket:%I64u", 
                                                retCode, retMsg, sysErr, ticket);
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("ORDER-DELETE-FAIL", xp, err_msg));
                if(IS_VALID(xp)) xp.SetString("[ORDER-DELETE-FAIL] " + err_msg);
                ResetLastError();
            }
        }
        else {
            return true; // 티켓을 찾을 수 없는 경우(이미 소멸) 성공
        }
        
        return res;
    }

    /**
     * @brief Layer 2: SID 기반 강제 소멸 (Fallback Sweep)
     */
    virtual bool SweepBySid(ICXParam* xp, string sid) override {
        bool all_cleared = true;
        XP_LOG_WARN(xp, CXAuditFormatter::Build("EXIT-SWEEP-START", xp, "Starting Fallback Sweep for SID:" + sid));
        
        //-- 포지션 스윕
        for(int i = PositionsTotal() - 1; i >= 0; i--) {
            ulong t = PositionGetTicket(i);
            if(PositionSelectByTicket(t)) {
                if(PositionGetInteger(POSITION_MAGIC) == (long)m_magic && PositionGetString(POSITION_COMMENT) == sid) {
                    XP_LOG_INFO(xp, CXAuditFormatter::Build("POS-CLOSE-SWEEP", xp, StringFormat("Sending Request [Ticket:%I64u]", t)));
                    if(!m_trade.PositionClose(t)) {
                        all_cleared = false;
                        string err_msg = StringFormat("SWEEP FAILED for Ticket:%I64u", t);
                        XP_LOG_ERROR(xp, CXAuditFormatter::Build("POS-CLOSE-FAIL", xp, err_msg));
                        if(IS_VALID(xp)) xp.SetString("[POS-CLOSE-FAIL] " + err_msg);
                    }
                }
            }
        }
        //-- 주문 스윕
        for(int i = OrdersTotal() - 1; i >= 0; i--) {
            ulong t = OrderGetTicket(i);
            if(OrderSelect(t)) {
                if(OrderGetInteger(ORDER_MAGIC) == (long)m_magic && OrderGetString(ORDER_COMMENT) == sid) {
                    XP_LOG_INFO(xp, CXAuditFormatter::Build("ORDER-DELETE-SWEEP", xp, StringFormat("Sending Request [Ticket:%I64u]", t)));
                    if(!m_trade.OrderDelete(t)) {
                        all_cleared = false;
                        string err_msg = StringFormat("SWEEP FAILED for Ticket:%I64u", t);
                        XP_LOG_ERROR(xp, CXAuditFormatter::Build("ORDER-DELETE-FAIL", xp, err_msg));
                        if(IS_VALID(xp)) xp.SetString("[ORDER-DELETE-FAIL] " + err_msg);
                    }
                }
            }
        }
        return all_cleared;
    }

    /**
     * @brief Layer 3: 터미널 존재 여부 확인 (SSOT Check)
     */
    virtual bool VerifyPhysicalAbsence(string sid) override {
        for(int i = 0; i < PositionsTotal(); i++) {
            ulong t = PositionGetTicket(i);
            if(PositionSelectByTicket(t)) {
                if(PositionGetInteger(POSITION_MAGIC) == (long)m_magic && PositionGetString(POSITION_COMMENT) == sid) return false;
            }
        }
        for(int i = 0; i < OrdersTotal(); i++) {
            ulong t = OrderGetTicket(i);
            if(OrderSelect(t)) {
                if(OrderGetInteger(ORDER_MAGIC) == (long)m_magic && OrderGetString(ORDER_COMMENT) == sid) return false;
            }
        }
        return true;
    }

    virtual void Reset() override { m_magic = 0; }
};

#endif



