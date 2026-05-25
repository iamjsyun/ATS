#ifndef CXSESSIONACTIVE_MQH
#define CXSESSIONACTIVE_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Core\Interfaces\IXPositionManager.mqh"
#include "..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\Core\Interfaces\IXPriceTracker.mqh"
#include "..\Core\Interfaces\ICXPriceManager.mqh"

/**
 * @class CXSessionActive
 * @brief 포지션 운용 및 익절 트레일링(Active, TrailingStop) 단계를 전담하는 세션 클래스 (v18.0)
 */
class CXSessionActive : public CXTradingSessionBase {
private:
    IXPositionManager*   m_posMgr;
    ICXInventoryManager* m_inventoryManager;
    IXPriceTracker*      m_priceTracker;
    ICXPriceManager*     m_priceManager;

public:
    CXSessionActive(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionActive() {
        SAFE_DELETE(m_posMgr);
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_priceTracker);
        SAFE_DELETE(m_priceManager);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        m_posMgr           = factory.CreatePositionManager(m_ctx);
        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        m_priceTracker     = factory.CreatePriceTracker(m_ctx);
        m_priceManager     = factory.CreatePriceManager(m_ctx);

        m_ctx.Register("pos_mgr",       m_posMgr);
        m_ctx.Register("inventory_mgr", m_inventoryManager);
        m_ctx.Register("price_tracker", m_priceTracker);
        m_ctx.Register("price_mgr",     m_priceManager);
        
        XP_LOG_DEBUG(NULL, "[SESSION-ACTIVE] Bootstrap Complete. Managers initialized.");
    }
};

#endif
