#ifndef CXINVENTORYMANAGER_MQH
#define CXINVENTORYMANAGER_MQH

#include "..\..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\..\Core\Defines\CXDefine.mqh"
#include "..\..\Shared\Logging\CXAuditFormatter.mqh"
#include "..\..\Core\Interfaces\IXTerminalPlatform.mqh"
#include "..\..\Core\Interfaces\ICXContext.mqh"

/**
 * @class CXInventoryManager
 * @brief 터미널 실물 자산 상태 확인 및 동기화 구현체 (v13.5 UAF Standard)
 */
class CXInventoryManager : public ICXInventoryManager {
private:
    ICXContext*         m_ctx;
    IXTerminalPlatform* m_terminal;

public:
    CXInventoryManager(ICXContext* ctx) : m_ctx(ctx) {
        m_terminal = CX_GET_OBJ(m_ctx, "terminal_platform", IXTerminalPlatform);
    }
    virtual ~CXInventoryManager() {}

    /**
     * @brief [v13.4 Audit] 인벤토리 요약 감사 문자열 생성
     */
    virtual string GetAuditString(ICXParam* xp, string actionLabel = "") override {
        int posTotal = m_terminal.GetPositionsTotal();
        int ordTotal = m_terminal.GetOrdersTotal();
        string spec = StringFormat("PosCount:%d, OrdCount:%d", posTotal, ordTotal);
        return CXAuditFormatter::Build(actionLabel, xp, spec);
    }

    virtual bool IsPositionExists(ulong ticket) override {
        return m_terminal.IsPositionExists(ticket);
    }

    virtual bool IsOrderExists(ulong ticket) override {
        return m_terminal.IsOrderExists(ticket);
    }

    virtual bool IsAssetExists(ulong ticket, int type) override {
        if(ticket <= 0) return false;
        
        // 1. 포지션이 존재하면 타입에 상관없이 실물 자산이 있는 것으로 간주 (진입 완료)
        if(IsPositionExists(ticket)) return true;
        
        // 2. 대기 오더인 경우, 오더가 살아있는지 확인
        if(type != ORDER_MARKET && IsOrderExists(ticket)) return true;
        
        return false;
    }

    /**
     * @brief 실물 자산의 데이터를 내부 신호 모델에 동기화 (Shadowing)
     */
    virtual bool SyncToSignal(ICXSignal* sig) override {
        if(IS_INVALID(sig)) return false;
        
        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) return false;

        // 1. 포지션 동기화 (체결된 상태)
        if(m_terminal.IsPositionExists(ticket)) {
            sig.SetLot(m_terminal.GetPositionVolume(ticket));
            sig.SetPriceOpen(m_terminal.GetPositionPriceOpen(ticket));
            sig.SetSL(m_terminal.GetPositionSL(ticket));
            sig.SetTP(m_terminal.GetPositionTP(ticket));
            return true;
        }
        
        // 2. 오더 동기화 (대기 상태)
        if(m_terminal.IsOrderExists(ticket)) {
            sig.SetLot(m_terminal.GetOrderVolume(ticket));
            sig.UpdatePriceSignal(m_terminal.GetOrderPriceOpen(ticket));
            sig.SetSL(m_terminal.GetOrderSL(ticket));
            sig.SetTP(m_terminal.GetOrderTP(ticket));
            return true;
        }

        return false;
    }

    virtual double GetCurrentVolume(ulong ticket, bool isPosition) override {
        if(isPosition) {
            return m_terminal.GetPositionVolume(ticket);
        }
        return m_terminal.GetOrderVolume(ticket);
    }

    virtual double GetCurrentPriceOpen(ulong ticket, bool isPosition) override {
        if(isPosition) {
            return m_terminal.GetPositionPriceOpen(ticket);
        }
        return m_terminal.GetOrderPriceOpen(ticket);
    }

    virtual double GetCurrentSL(ulong ticket) override {
        if(m_terminal.IsPositionExists(ticket)) return m_terminal.GetPositionSL(ticket);
        if(m_terminal.IsOrderExists(ticket)) return m_terminal.GetOrderSL(ticket);
        return 0;
    }

    virtual double GetCurrentTP(ulong ticket) override {
        if(m_terminal.IsPositionExists(ticket)) return m_terminal.GetPositionTP(ticket);
        if(m_terminal.IsOrderExists(ticket)) return m_terminal.GetOrderTP(ticket);
        return 0;
    }

    virtual double GetCurrentProfit(ulong ticket) override {
        return m_terminal.GetPositionProfit(ticket);
    }

    /**
     * @brief 히스토리를 추적하여 청산 사유 및 최종 상태 반환
     */
    virtual int CheckHistoryClosure(ulong ticket, string &reason) override {
        return m_terminal.CheckHistoryClosure(ticket, reason);
    }
};

#endif
