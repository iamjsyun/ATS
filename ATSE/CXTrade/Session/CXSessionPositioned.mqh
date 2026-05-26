#ifndef CXSESSIONPOSITIONED_MQH
#define CXSESSIONPOSITIONED_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Platform\Core\Interfaces\IXPositionManager.mqh"
#include "..\Platform\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\Platform\Core\Interfaces\IXPriceTracker.mqh"
#include "..\Platform\Core\Interfaces\ICXPriceManager.mqh"

#include "..\Platform\Core\Interfaces\IXOrderManager.mqh"
#include "..\Platform\Core\Interfaces\IXExitManager.mqh"

/**
 * @class CXSessionPositioned
 * @brief 실물 포지션 확보 완료 및 운용(Active, TrailingStop) 단계를 전담하는 클래스 (v18.6)
 */
class CXSessionPositioned : public CXTradingSessionBase {
private:
    IXPositionManager*   m_posMgr;
    ICXInventoryManager* m_inventoryManager;
    IXPriceTracker*      m_priceTracker;
    ICXPriceManager*     m_priceManager;
    IXOrderManager*      m_orderMgr;
    IXExitManager*       m_exitMgr;

public:
    CXSessionPositioned(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionPositioned() {
        SAFE_DELETE(m_posMgr);
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_priceTracker);
        SAFE_DELETE(m_priceManager);
        SAFE_DELETE(m_orderMgr);
        SAFE_DELETE(m_exitMgr);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        // [v18.15 Full Lifecycle Bootstrap]
        m_posMgr           = factory.CreatePositionManager(m_ctx);
        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        m_priceTracker     = factory.CreatePriceTracker(m_ctx);
        m_priceManager     = factory.CreatePriceManager(m_ctx);
        m_orderMgr         = factory.CreateOrderManager(m_ctx);
        m_exitMgr          = factory.CreateExitManager(m_ctx);

        m_ctx.Register("pos_mgr",       m_posMgr);
        m_ctx.Register("inventory_mgr", m_inventoryManager);
        m_ctx.Register("price_tracker", m_priceTracker);
        m_ctx.Register("price_mgr",     m_priceManager);
        m_ctx.Register("order_mgr",     m_orderMgr);
        m_ctx.Register("exit_mgr",      m_exitMgr);
        
        XP_LOG_DEBUG(NULL, "[SESSION-POSITIONED] Bootstrap Complete. Full-Lifecycle Managers initialized.");
    }
};

#endif
