#ifndef CXSESSIONENTRY_MQH
#define CXSESSIONENTRY_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Platform\Core\Interfaces\IXEntryManager.mqh"
#include "..\Platform\Core\Interfaces\IXOrderManager.mqh"
#include "..\Platform\Core\Interfaces\ICXPriceManager.mqh"
#include "..\Platform\Core\Interfaces\ICXRiskManager.mqh"
#include "..\Platform\Core\Interfaces\ICXInventoryManager.mqh"

#include "..\Platform\Core\Interfaces\IXPositionManager.mqh"
#include "..\Platform\Core\Interfaces\IXExitManager.mqh"

/**
 * @class CXSessionEntry
 * @brief 진입(Validating, Executing) 단계를 전담하는 세션 클래스 (v18.0)
 */
class CXSessionEntry : public CXTradingSessionBase {
private:
    IXEntryManager*      m_entryMgr;
    IXOrderManager*      m_orderMgr;
    ICXPriceManager*     m_priceManager;
    ICXRiskManager*      m_riskManager;
    ICXInventoryManager* m_inventoryManager;
    IXPositionManager*   m_posMgr;
    IXExitManager*       m_exitMgr;

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
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_posMgr);
        SAFE_DELETE(m_exitMgr);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        // [v18.15 Full Lifecycle Bootstrap]
        m_entryMgr         = factory.CreateEntryManager(m_ctx);
        m_orderMgr         = factory.CreateOrderManager(m_ctx);
        m_priceManager     = factory.CreatePriceManager(m_ctx);
        m_riskManager      = factory.CreateRiskManager(m_ctx);
        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        m_posMgr           = factory.CreatePositionManager(m_ctx);
        m_exitMgr          = factory.CreateExitManager(m_ctx);

        m_ctx.Register("entry_mgr",     m_entryMgr);
        m_ctx.Register("order_mgr",     m_orderMgr);
        m_ctx.Register("price_mgr",     m_priceManager);
        m_ctx.Register("risk_mgr",      m_riskManager);
        m_ctx.Register("inventory_mgr", m_inventoryManager);
        m_ctx.Register("pos_mgr",       m_posMgr);
        m_ctx.Register("exit_mgr",      m_exitMgr);
        
        XP_LOG_DEBUG(NULL, "[SESSION-ENTRY] Bootstrap Complete. Full-Lifecycle Managers initialized.");
    }
};

#endif
