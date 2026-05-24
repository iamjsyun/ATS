#ifndef CXPOSITIONMANAGER_MQH
#define CXPOSITIONMANAGER_MQH

#include "..\..\Core\Interfaces\IXPositionManager.mqh"
#include "..\..\Core\Interfaces\ICXContext.mqh"
#include "..\..\Core\Interfaces\ICXParam.mqh"
#include "..\..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\..\Core\Defines\CXDefine.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"
#include "..\..\Shared\Logging\CXMessageProvider.mqh"
#include "..\..\Shared\Logging\CXAuditFormatter.mqh"
#include <Trade\Trade.mqh>

/**
 * @class CXPositionManager
 * @brief 샌드박스 세션 내의 포지션 감시 및 사후 관리 담당 (v13.5 UAF & Resilience Standard)
 */
class CXPositionManager : public IXPositionManager {
private:
    ulong               m_ticket;
    ICXContext*         m_ctx;
    CTrade              m_trade;

public:
    CXPositionManager(ICXContext* ctx) : m_ctx(ctx), m_ticket(0) {}
    virtual ~CXPositionManager() override {}

    virtual void SetMagic(ulong magic) override { m_trade.SetExpertMagicNumber(magic); }

    /**
     * @brief [v13.4 Audit] 포지션 감사 문자열 생성
     */
    virtual string GetAuditString(ICXParam* xp, string actionLabel = "") override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return "[" + actionLabel + "] INVALID_SIGNAL";

        ulong ticket = sig.GetTicket();
        double profit = 0;
        double currentSL = 0;
        
        if(PositionSelectByTicket(ticket)) {
            profit = PositionGetDouble(POSITION_PROFIT);
            currentSL = PositionGetDouble(POSITION_SL);
        }

        string spec = StringFormat("Profit:%.2f, SL:%.5f", profit, currentSL);
        return CXAuditFormatter::Build(actionLabel, xp, spec);
    }

    /**
     * @brief 포지션 유효성 확인 및 상태 업데이트
     */
    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(m_ctx) || IS_INVALID(xp)) return;
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket == 0) return;

        //--- [v11.3 SSOC Resolution]
        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_INVALID(invMgr)) {
            XP_LOG_ERROR(xp, CXAuditFormatter::Build("POS-MANAGER", xp, "CRITICAL: InventoryManager Missing."));
            return;
        }

        // 1. 터미널에 포지션이 살아있는지 확인 (SSOC) 및 SID 검증
        if(PositionSelectByTicket(ticket)) {
            if(PositionGetString(POSITION_COMMENT) == sig.GetSid()) {
                return; // 정상: 티켓과 SID 모두 일치
            } else {
                string mismatchMsg = StringFormat("SID Mismatch for Ticket:%I64u. (Found:%s, Expected:%s)", 
                                             ticket, PositionGetString(POSITION_COMMENT), sig.GetSid());
                XP_LOG_WARN(xp, CXAuditFormatter::Build("POS-MANAGER", xp, mismatchMsg));
                // SID가 다르면 내 자산이 아니므로 아래의 부재/히스토리 로직으로 진행
            }
        }

        // 1.1 [v11.6] 포지션은 없으나 '대기 오더'로 살아있는지 확인
        if(OrderSelect(ticket)) {
            if(OrderGetString(ORDER_COMMENT) == sig.GetSid()) {
                XP_LOG_TRACE(xp, CXAuditFormatter::Build("POS-MANAGER", xp, StringFormat("OK: Position missing but Order:%I64u still active.", ticket)));
                return; 
            }
        }

        // 2. 포지션/오더 모두 사라졌다면(Broker Close), 히스토리를 뒤져 청산 사유 파악 (SSOC)
        string reason = "";
        int status = invMgr.CheckHistoryClosure(ticket, reason);

        if(status != XE_UNKNOWN) {
            CXMessageProvider::UpdateStatus(sig, status, reason);
            XP_LOG_INFO(xp, CXAuditFormatter::Build("POS-MANAGER", xp, "Asset closed by broker: " + reason));
            return;
        }
        
        // 3. 딜(Deal) 히스토리에서도 찾지 못한 경우 (동기화 지연 대비 Retry)
        string retryKey = StringFormat("HistRetry_%I64u", ticket);
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
            
            XP_LOG_DEBUG(xp, CXAuditFormatter::Build("POS-MANAGER-RETRY", xp, StringFormat("Retry:%d/5", retryCount + 1)));
            return; // 다음 틱에서 재시도
        }

        // 5회 이상 실패 시 보수적으로 청산 처리
        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, "Position Missing & History Timeout");
        XP_LOG_WARN(xp, CXAuditFormatter::Build("POS-MANAGER-TIMEOUT", xp));
    }

    /**
     * @brief 브로커 포지션 수정 (SL/TP) 및 상태 재확인
     */
    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) override {
        XP_LOG_INFO(xp, GetAuditString(xp, "POS-MODIFY-START"));

        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_INVALID(invMgr)) return false;

        // 1. 수정 시도
        if(!m_trade.PositionModify(ticket, sl, tp)) {
            string retMsg = m_trade.ResultRetcodeDescription();
            uint retCode = m_trade.ResultRetcode();
            int sysErr = GetLastError();
            string spec = StringFormat("Broker Code:%u(%s), SysErr:%d", retCode, retMsg, sysErr);
            string err_msg = CXAuditFormatter::Build("POS-MODIFY-FAIL", xp, spec);
            
            XP_LOG_ERROR(xp, err_msg);
            if(IS_VALID(xp)) xp.SetString(err_msg);
            ResetLastError();
            return false;
        }
        
        // 2. 재확인 (SSOC)
        if(invMgr.IsPositionExists(ticket)) {
            double currentSL = invMgr.GetCurrentSL(ticket);
            double currentTP = invMgr.GetCurrentTP(ticket);
            
            if(MathAbs(currentSL - sl) < _Point * 10 && MathAbs(currentTP - tp) < _Point * 10) {
                XP_LOG_OK(xp, GetAuditString(xp, "POS-MODIFY-SUCCESS"));
                return true;
            }
        }
        
        string vErr = CXAuditFormatter::Build("POS-MODIFY-VERIFY-FAIL", xp, StringFormat("ticket:%I64u", ticket));
        XP_LOG_ERROR(xp, vErr);
        if(IS_VALID(xp)) xp.SetString(vErr);
        return false;
    }
};

#endif
