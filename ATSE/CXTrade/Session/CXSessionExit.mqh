#ifndef CXSESSIONEXIT_MQH
#define CXSESSIONEXIT_MQH

#include "CXTradingSessionBase.mqh"
#include "..\Core\Interfaces\IXExitManager.mqh"
#include "..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\Core\Interfaces\IXOrderManager.mqh"

/**
 * @class CXSessionExit
 * @brief 청산 및 종료(Liquidating, Closed) 단계를 전담하는 세션 클래스 (v18.0)
 */
class CXSessionExit : public CXTradingSessionBase {
private:
    IXExitManager*       m_exitMgr;
    ICXInventoryManager* m_inventoryManager;
    IXOrderManager*      m_orderMgr;

public:
    CXSessionExit(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : CXTradingSessionBase(repo, globalCtx, factory) {
        Bootstrap(factory);
    }

    virtual ~CXSessionExit() {
        SAFE_DELETE(m_exitMgr);
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_orderMgr);
    }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        InitBase(factory);
        if(IS_INVALID(m_ctx)) return;

        m_exitMgr          = factory.CreateExitManager(m_ctx);
        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        m_orderMgr         = factory.CreateOrderManager(m_ctx);

        m_ctx.Register("exit_mgr",      m_exitMgr);
        m_ctx.Register("inventory_mgr", m_inventoryManager);
        m_ctx.Register("order_mgr",     m_orderMgr);
        
        XP_LOG_DEBUG(NULL, "[SESSION-EXIT] Bootstrap Complete. Managers initialized.");
    }
};

#endif
