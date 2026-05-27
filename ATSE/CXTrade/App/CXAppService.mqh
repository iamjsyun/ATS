#ifndef CXAPPSERVICE_MQH
#define CXAPPSERVICE_MQH

#include "..\Platform\Core\Interfaces\ICXAppService.mqh"
#include "..\Platform\Core\Interfaces\ICXConfig.mqh"
#include "..\Platform\Core\Interfaces\IDatabase.mqh"
#include "..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\Platform\Core\Interfaces\ICXServiceFactory.mqh"
#include "..\Platform\Core\Interfaces\ICXSignalWatcher.mqh"
#include "..\Session\CXSessionManager.mqh"
#include "Orchestration\AppOrchestrator.mqh"
#include "..\Watcher\CXSignalWatcher.mqh"
#include "..\Platform\Core\Models\CXParam.mqh"
#include "..\Platform\Shared\Guard\CXGuard.mqh"
#include "..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"
#include "..\Platform\Core\Interfaces\IXGuard.mqh"
#include "Orchestration\CXStageFactory.mqh"
#include "Orchestration\CXTaskFactory.mqh"
#include "..\Platform\Shared\Logging\CXAuditFormatter.mqh"
#include "..\Platform\Shared\Logging\CXMessageProvider.mqh"
#include "Infra\CXServiceFactory.mqh"
#include "..\Platform\Core\Models\CXConfig.mqh"

#include "..\Platform\UI\CXUI.mqh"

/**
 * @class CXAppService
 * @brief EA의 전체 생명주기 및 의존성 주입을 총괄하는 서비스 (v14.47 Dynamic Session)
 */
class CXAppService : public ICXAppService {
private:
    ICXConfig*            m_config;
    IDatabase*            m_db;
    IRepository*          m_repo;
    ICXSessionManager*    m_sessionManager;
    ICXServiceFactory*    m_factory;
    ICXSignalWatcher*     m_watcher;
    ICXLogger*            m_logger;
    ICXContext*           m_globalContext;
    
    // Lifecycle-managed dependencies
    CXSequenceOrchestrator* m_orchestrator;
    IXGuard*              m_guard;
    IXTerminalPlatform*   m_terminalPlatform;
    ICXPriceManager*      m_priceManager;
    IXExitManager*        m_exitManager;
    CXUI*                 m_ui;

public:
    CXAppService() : m_config(NULL), m_db(NULL), m_repo(NULL), m_sessionManager(NULL), 
                    m_factory(NULL), m_watcher(NULL), m_logger(NULL), m_globalContext(NULL),
                    m_orchestrator(NULL), m_guard(NULL), m_terminalPlatform(NULL),
                    m_priceManager(NULL), m_exitManager(NULL), m_ui(NULL) {}

    virtual ~CXAppService() override {
        SAFE_DELETE(m_ui);
        SAFE_DELETE(m_watcher);
        SAFE_DELETE(m_sessionManager);
        SAFE_DELETE(m_repo);
        SAFE_DELETE(m_db);
        SAFE_DELETE(m_config);
        SAFE_DELETE(m_globalContext);
        SAFE_DELETE(m_logger);
        SAFE_DELETE(m_orchestrator);
        SAFE_DELETE(m_guard);
        SAFE_DELETE(m_terminalPlatform);
        SAFE_DELETE(m_priceManager);
        SAFE_DELETE(m_exitManager);
    }

    virtual bool Initialize(ICXConfig* config, ICXServiceFactory* factory) override {
        m_config = config;
        m_factory = factory;
        if(IS_INVALID(m_config) || IS_INVALID(m_factory)) return false;

        // 1. 글로벌 컨텍스트 구축
        m_globalContext = m_factory.CreateContext();
        if(IS_INVALID(m_globalContext)) return false;

        // 2. 핵심 인프라 서비스 초기화
        m_logger = m_factory.CreateLogger("System", m_config);
        m_orchestrator = new AppOrchestrator();
        m_guard = new CXGuard(m_globalContext);
        m_terminalPlatform = m_factory.CreateTerminalPlatform(m_globalContext);
        m_priceManager = m_factory.CreatePriceManager(m_globalContext);
        m_exitManager = m_factory.CreateExitManager(m_globalContext);

        m_globalContext.Register("logger", m_logger);
        m_globalContext.Register("config", m_config);
        m_globalContext.Register("orchestrator", m_orchestrator);
        m_globalContext.Register("guard", m_guard);
        m_globalContext.Register("terminal_platform", m_terminalPlatform);
        m_globalContext.Register("price_mgr", m_priceManager);
        m_globalContext.Register("exit_mgr", m_exitManager);

        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STAGE 1/6] Core Services Initialized.");

        // 3. DB & Repository 연결
        m_db = m_factory.CreateDatabase();
        if(IS_INVALID(m_db) || !m_db.Open(m_config.GetDatabaseName(), m_config.IsDatabaseCommon())) return false;
        
        m_repo = m_factory.CreateRepository(m_db);
        if(IS_INVALID(m_repo)) return false;
        m_globalContext.Register("db", m_db); // Register db for zombie reverse injection
        m_globalContext.Register("repo", m_repo); // [v15.6 Fix] Watcher Discovery & Spawning dependency
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STAGE 2/6] Database Connected.");

        // 4. 세션 매니저 초기화 (동적 인스턴스 방식)
        m_sessionManager = new CXSessionManager();
        m_sessionManager.Initialize(m_repo, m_globalContext, m_factory);
        m_globalContext.Register("session_mgr", m_sessionManager);
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STAGE 3/6] Session Manager Initialized.");

        // 5. 신호 감시자 (Watcher) 초기화 (통합 루프)
        m_watcher = new CXSignalWatcher(m_repo, m_config, m_sessionManager, m_globalContext, m_factory, "Unified");
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STAGE 4/6] Unified Signal Watcher Initialized.");

        // 6. 대시보드 (UI) 초기화
        m_ui = new CXUI(m_globalContext);
        if(IS_VALID(m_ui)) m_ui.Initialize();
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STAGE 5/6] Dashboard Initialized.");
        
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STAGE 6/6] System Bootstrap Complete.");
        return true;
    }

    virtual void Pulse() override {
        CXParam xp;
        
        //-- 1. 신호 감시 (통합 워처 가동)
        if(IS_VALID(m_watcher)) m_watcher.Pulse(GetPointer(xp));
        
        //-- 2. 활성 세션 구동 및 GC (Execution & Cleanup)
        if(IS_VALID(m_sessionManager)) m_sessionManager.Pulse(GetPointer(xp));

        //-- 3. 대시보드 갱신
        if(IS_VALID(m_ui)) m_ui.Refresh();
    }

    virtual void OnTradeTransaction(const MqlTradeTransaction& trans,
                                    const MqlTradeRequest& request,
                                    const MqlTradeResult& result) override {
        CXParam xp;
        xp.SetEvent(EVENT_TRANSACTION);
        xp.SetTransaction(trans); // Assuming CXParam has this or use raw access if needed
        
        if(IS_VALID(m_sessionManager)) m_sessionManager.Pulse(GetPointer(xp));
    }
};

#endif
