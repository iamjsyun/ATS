#ifndef CXSESSIONENTRY_MQH
#define CXSESSIONENTRY_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Core\Interfaces\IXEntryManager.mqh"
#include "..\Core\Interfaces\IXOrderManager.mqh"
#include "..\Core\Interfaces\ICXPriceManager.mqh"
#include "..\Core\Interfaces\ICXRiskManager.mqh"

/**
 * @class CXSessionEntry
 * @brief 진입(Validating, Executing) 단계를 전담하는 세션 클래스 (v18.0)
 */
class CXSessionEntry : public CXTradingSessionBase {
private:
    IXEntryManager*    m_entryMgr;
    IXOrderManager*    m_orderMgr;
    ICXPriceManager*   m_priceManager;
    ICXRiskManager*    m_riskManager;

public:
    CXSessionEntry(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionEntry() {
        SAFE_DELETE(m_entryMgr);
        SAFE_DELETE(m_orderMgr);
        SAFE_DELETE(m_priceManager);
        SAFE_DELETE(m_riskManager);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        // 진입 단계에 필요한 매니저만 생성 및 등록
        m_entryMgr     = factory.CreateEntryManager(m_ctx);
        m_orderMgr     = factory.CreateOrderManager(m_ctx);
        m_priceManager = factory.CreatePriceManager(m_ctx);
        m_riskManager  = factory.CreateRiskManager(m_ctx);

        m_ctx.Register("entry_mgr", m_entryMgr);
        m_ctx.Register("order_mgr", m_orderMgr);
        m_ctx.Register("price_mgr", m_priceManager);
        m_ctx.Register("risk_mgr",  m_riskManager);
        
        XP_LOG_DEBUG(NULL, "[SESSION-ENTRY] Bootstrap Complete. Managers initialized.");
    }
};

#endif
