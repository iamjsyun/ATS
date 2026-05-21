#ifndef CXPOSITIONMANAGER_MQH
#define CXPOSITIONMANAGER_MQH

#include "..\..\Interfaces\IXPositionManager.mqh"
#include "..\..\Interfaces\ICXContext.mqh"
#include "..\..\Interfaces\ICXParam.mqh"
#include "..\..\Interfaces\CXDefine.mqh"
#include "..\..\Interfaces\CXMacros.mqh"
#include <Trade\Trade.mqh>

#include "..\..\Interfaces\IXTrailingStrategy.mqh"

/**
 * @class CXPositionManager
 * @brief 샌드박스 세션 내의 포지션 감시 및 사후 관리 담당
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

    void SetMagic(ulong magic) { m_trade.SetExpertMagicNumber(magic); }

    /**
     * @brief 포지션 유효성 확인 및 상태 업데이트
     */
    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(m_ctx) || IS_INVALID(xp)) return;
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket == 0) return;

        // 1. 터미널에 포지션이 살아있는지 확인
        if(PositionSelectByTicket(ticket)) {
            return; // 정상
        }

        // 2. 포지션이 사라졌다면(Broker Close), 히스토리를 뒤져 청산 사유 파악
        if(HistorySelect(0, TimeCurrent())) {
            int total = HistoryDealsTotal();
            for(int i = total - 1; i >= 0; i--) {
                ulong dealTicket = HistoryDealGetTicket(i);
                if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == ticket &&
                   HistoryDealGetInteger(dealTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
                   
                    string comment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
                    // 터미널 자동 생성 코멘트에 SL 또는 TP 문자열이 포함됨
                    if(StringFind(comment, "[sl]") >= 0 || StringFind(comment, "sl") >= 0) {
                        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SL, "Closed by SL");
                    } else if(StringFind(comment, "[tp]") >= 0 || StringFind(comment, "tp") >= 0) {
                        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_TP, "Closed by TP");
                    } else {
                        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, "Closed by Broker/Terminal");
                    }
                    
                    XP_LOG_INFO(xp, StringFormat("[POS-MANAGER] Position closed by broker. Reason: %s", comment));
                    return;
                }
            }
        }
        
        // 3. 딜(Deal) 히스토리에서도 찾지 못한 경우 (동기화 지연 또는 이상 삭제)
        // 보수적으로 청산 신호로 간주하여 시퀀스를 넘김
        CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, "Position Not Found in Terminal");
        XP_LOG_WARN(xp, "[POS-MANAGER] Position missing but not in history. Force closing.");
    }

    /**
     * @brief 티켓으로 포지션 선택
     */
    bool SelectPosition(ICXParam* xp) {
        return false;
    }

    /**
     * @brief 브로커 포지션 수정 (SL/TP) 및 상태 재확인
     */
    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) override {
        XP_LOG_INFO(xp, StringFormat("[POS-MODIFY] Sending Request: [Ticket:%I64u, SL:%.5f, TP:%.5f]", 
                                        ticket, sl, tp));

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
        
        // 2. 재확인
        if(PositionSelectByTicket(ticket)) {
            double currentSL = PositionGetDouble(POSITION_SL);
            double currentTP = PositionGetDouble(POSITION_TP);
            
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



