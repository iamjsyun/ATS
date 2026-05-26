#ifndef CXSESSIONPENDING_MQH
#define CXSESSIONPENDING_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Platform\Core\Interfaces\ICXInventoryManager.mqh"

#include "..\Platform\Core\Interfaces\IXOrderManager.mqh"
#include "..\Platform\Core\Interfaces\ICXPriceManager.mqh"
#include "..\Platform\Core\Interfaces\IXPositionManager.mqh"
#include "..\Platform\Core\Interfaces\IXExitManager.mqh"

/**
 * @class CXSessionPending
 * @brief 터미널 오더 안착 및 접수 확인(Pending) 단계를 전담하는 클래스 (v18.6)
 */
class CXSessionPending : public CXTradingSessionBase {
private:
    IXOrderManager*      m_orderMgr;
    ICXPriceManager*     m_priceManager;
    ICXInventoryManager* m_inventoryManager;
    IXPositionManager*   m_posMgr;
    IXExitManager*       m_exitMgr;

public:
    CXSessionPending(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionPending() {
        SAFE_DELETE(m_orderMgr);
        SAFE_DELETE(m_priceManager);
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_posMgr);
        SAFE_DELETE(m_exitMgr);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        m_orderMgr         = factory.CreateOrderManager(m_ctx);
        m_priceManager     = factory.CreatePriceManager(m_ctx);
        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        m_posMgr           = factory.CreatePositionManager(m_ctx);
        m_exitMgr          = factory.CreateExitManager(m_ctx);

        m_ctx.Register("order_mgr",     m_orderMgr);
        m_ctx.Register("price_mgr",     m_priceManager);
        m_ctx.Register("inventory_mgr", m_inventoryManager);
        m_ctx.Register("pos_mgr",       m_posMgr);
        m_ctx.Register("exit_mgr",      m_exitMgr);
        
        XP_LOG_DEBUG(NULL, "[SESSION-PENDING] Bootstrap Complete. Full-Lifecycle Managers initialized.");
    }
};

#endif
