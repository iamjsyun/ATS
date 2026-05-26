#ifndef CXSESSIONPENDING_MQH
#define CXSESSIONPENDING_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Platform\Core\Interfaces\ICXInventoryManager.mqh"

/**
 * @class CXSessionPending
 * @brief 터미널 오더 안착 및 접수 확인(Pending) 단계를 전담하는 클래스 (v18.6)
 */
class CXSessionPending : public CXTradingSessionBase {
private:
    ICXInventoryManager* m_inventoryManager;

public:
    CXSessionPending(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionPending() {
        SAFE_DELETE(m_inventoryManager);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        m_inventoryManager = factory.CreateInventoryManager(m_ctx);

        m_ctx.Register("inventory_mgr", m_inventoryManager);
        
        XP_LOG_DEBUG(NULL, "[SESSION-PENDING] Bootstrap Complete. Managers initialized.");
    }
};

#endif
