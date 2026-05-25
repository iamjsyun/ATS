#ifndef CXSESSIONTRAILINGENTRY_MQH
#define CXSESSIONTRAILINGENTRY_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Core\Interfaces\IXOrderManager.mqh"
#include "..\Core\Interfaces\ICXPriceManager.mqh"
#include "..\Core\Interfaces\ICXInventoryManager.mqh"

/**
 * @class CXSessionTrailingEntry
 * @brief 대기 오더의 실시간 가격 추격(Active TE) 단계를 전담하는 클래스 (v18.6)
 */
class CXSessionTrailingEntry : public CXTradingSessionBase {
private:
    IXOrderManager*      m_orderMgr;
    ICXPriceManager*     m_priceManager;
    ICXInventoryManager* m_inventoryManager;

public:
    CXSessionTrailingEntry(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionTrailingEntry() {
        SAFE_DELETE(m_orderMgr);
        SAFE_DELETE(m_priceManager);
        SAFE_DELETE(m_inventoryManager);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        m_orderMgr         = factory.CreateOrderManager(m_ctx);
        m_priceManager     = factory.CreatePriceManager(m_ctx);
        m_inventoryManager = factory.CreateInventoryManager(m_ctx);

        m_ctx.Register("order_mgr",     m_orderMgr);
        m_ctx.Register("price_mgr",     m_priceManager);
        m_ctx.Register("inventory_mgr", m_inventoryManager);
        
        XP_LOG_DEBUG(NULL, "[SESSION-TRAILING-ENTRY] Bootstrap Complete. Managers initialized.");
    }
};

#endif
