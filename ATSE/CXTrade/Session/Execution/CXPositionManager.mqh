#ifndef CXPOSITIONMANAGER_MQH
#define CXPOSITIONMANAGER_MQH

#include "..\..\Interfaces\IXPositionManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include "..\..\Infra\CXMessageProvider.mqh"
#include <Trade\Trade.mqh>

#include "..\..\Interfaces\IXTrailingStrategy.mqh"

/**
 * @class CXPositionManager
 * @brief 샌드박스 세션 내의 포지션 감시 및 사후 관리 담당 (v11.3 SSOC Alignment)
 */
class CXPositionManager : public IXPositionManager {
private:
    ulong               m_ticket;
    ICXContext*         m_ctx;
    CTrade              m_trade;
    IXTrailingStrategy* m_exitTrl; // 익트 전략 (Pluggable)

public:
    CXPositionManager(ICXContext* ctx) : m_ctx(ctx), m_ticket(0), m_exitTrl(NULL) {}
    virtual ~CXPositionManager() override { SAFE_DELETE(m_exitTrl); }

    void SetTrailingStrategy(IXTrailingStrategy* strategy) {
        SAFE_DELETE(m_exitTrl);
        m_exitTrl = strategy;
    }

    virtual void SetMagic(ulong magic) override { m_trade.SetExpertMagicNumber(magic); }

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
            XP_LOG_ERROR(xp, "[POS-MANAGER] CRITICAL: InventoryManager Missing.");
            return;
        }

        // 1. 터미널에 포지션이 살아있는지 확인 (SSOC)
        if(invMgr.IsPositionExists(ticket)) {
            return; // 포지션 존재 시 정상
        }

        // 1.1 [v11.6] 포지션은 없으나 '대기 오더'로 살아있는지 확인
        if(invMgr.IsOrderExists(ticket)) {
            XP_LOG_TRACE(xp, StringFormat("[POS-MANAGER] OK: Position missing but Order:%I64u still active.", ticket));
            return; 
        }

        // 2. 포지션/오더 모두 사라졌다면(Broker Close), 히스토리를 뒤져 청산 사유 파악 (SSOC)
        string reason = "";
        int status = invMgr.CheckHistoryClosure(ticket, reason);

        if(status != XE_UNKNOWN) {
            CXMessageProvider::UpdateStatus(sig, status, reason);
            XP_LOG_INFO(xp, StringFormat("[POS-MANAGER] Asset closed/canceled by broker. Reason: %s", reason));
            return;
        }
        
        // 3. 딜(Deal) 히스토리에서도 찾지 못한 경우 (동기화 지연 또는 이상 삭제)
        // 보수적으로 청산 신호로 간주하여 시퀀스를 넘김
        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, "Position Not Found in Terminal");
        XP_LOG_WARN(xp, "[POS-MANAGER] Position missing but not in history. Force closing.");
    }

    /**
     * @brief 브로커 포지션 수정 (SL/TP) 및 상태 재확인
     */
    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) override {
        XP_LOG_INFO(xp, StringFormat("[POS-MODIFY] Sending Request: [Ticket:%I64u, SL:%.5f, TP:%.5f]", 
                                        ticket, sl, tp));

        ICXInventoryManager* invMgr = CX_GET_OBJ(m_ctx, "inventory_mgr", ICXInventoryManager);
        if(IS_INVALID(invMgr)) return false;

        // 1. 수정 시도
        if(!m_trade.PositionModify(ticket, sl, tp)) {
            string retMsg = m_trade.ResultRetcodeDescription();
            uint retCode = m_trade.ResultRetcode();
            int sysErr = GetLastError();
            string err_msg = StringFormat("[POS-MODIFY-FAIL] Broker Code:%u(%s), SysErr:%d. Original Params: [Ticket:%I64u, SL:%.5f, TP:%.5f]", 
                                            retCode, retMsg, sysErr, ticket, sl, tp);
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
                XP_LOG_OK(xp, StringFormat("[POS-MODIFY] SUCCESS: Ticket %I64u Modified.", ticket));
                return true;
            }
        }
        
        string vErr = StringFormat("[POS-MODIFY-FAIL] VERIFY FAILED: Modification sent but values not reflected for ticket:%I64u", ticket);
        XP_LOG_ERROR(xp, vErr);
        if(IS_VALID(xp)) xp.SetString(vErr);
        return false;
    }

    void Reset() {
        m_ticket = 0;
    }
};

#endif
