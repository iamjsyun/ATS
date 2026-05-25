#ifndef CXSESSIONPENDING_MQH
#define CXSESSIONPENDING_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\Core\Interfaces\IXOrderManager.mqh"
#include "..\Core\Interfaces\ICXPriceManager.mqh"

/**
 * @class CXSessionPending
 * @brief 대기 및 진입 트레일링(Pending, TrailingEntry) 단계를 전담하는 세션 클래스 (v18.0)
 */
class CXSessionPending : public CXTradingSessionBase {
private:
    ICXInventoryManager* m_inventoryManager;
    IXOrderManager*      m_orderMgr;
    ICXPriceManager*     m_priceManager;

public:
    CXSessionPending(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionPending() {
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_orderMgr);
        SAFE_DELETE(m_priceManager);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        m_orderMgr         = factory.CreateOrderManager(m_ctx);
        m_priceManager     = factory.CreatePriceManager(m_ctx);

        m_ctx.Register("inventory_mgr", m_inventoryManager);
        m_ctx.Register("order_mgr",     m_orderMgr);
        m_ctx.Register("price_mgr",     m_priceManager);
        
        XP_LOG_DEBUG(NULL, "[SESSION-PENDING] Bootstrap Complete. Managers initialized.");
    }
};

#endif
