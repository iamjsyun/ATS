#ifndef CXAPPSERVICE_MQH
#define CXAPPSERVICE_MQH

#include "..\Core\Interfaces\ICXAppService.mqh"
#include "..\Core\Interfaces\ICXConfig.mqh"
#include "..\Core\Interfaces\IDatabase.mqh"
#include "..\Core\Interfaces\IRepository.mqh"
#include "..\Core\Interfaces\ICXSessionManager.mqh"
#include "..\Core\Interfaces\ICXServiceFactory.mqh"
#include "..\Core\Interfaces\ICXSignalWatcher.mqh"
#include "Infra\CXSessionManager.mqh"
#include "Infra\AppOrchestrator.mqh"
#include "Logic\CXSignalWatcher.mqh"
#include "Logic\CXTerminalScanner.mqh"
#include "Logic\CXReverseInjector.mqh"
#include "..\Core\Models\CXParam.mqh"
#include "..\Shared\Guard\CXGuard.mqh"
#include "..\Session\Sequence\CXSequenceOrchestrator.mqh"
#include "..\Core\Interfaces\IXGuard.mqh"
#include "..\Session\Sequence\CXStepFactory.mqh"
#include "..\Session\Sequence\CXTaskFactory.mqh"
#include "..\Shared\Logging\CXAuditFormatter.mqh"
#include "..\Shared\Logging\CXMessageProvider.mqh"
#include "Infra\CXServiceFactory.mqh"
#include "..\Core\Models\CXConfig.mqh"

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
    
    CXTerminalScanner*    m_scanner;
    CXReverseInjector*    m_injector;

public:
    CXAppService() : m_config(NULL), m_db(NULL), m_repo(NULL), m_sessionManager(NULL), 
                    m_factory(NULL), m_watcher(NULL), m_logger(NULL), m_globalContext(NULL),
                    m_scanner(NULL), m_injector(NULL) {}

    virtual ~CXAppService() override {
        SAFE_DELETE(m_watcher);
        SAFE_DELETE(m_sessionManager);
        SAFE_DELETE(m_repo);
        SAFE_DELETE(m_db);
        SAFE_DELETE(m_config);
        SAFE_DELETE(m_globalContext);
        SAFE_DELETE(m_logger);
        SAFE_DELETE(m_scanner);
        SAFE_DELETE(m_injector);
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
        m_globalContext.Register("logger", m_logger);
        m_globalContext.Register("config", m_config);
        m_globalContext.Register("orchestrator", new AppOrchestrator());
        m_globalContext.Register("guard", new CXGuard(m_globalContext));

        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 1/6] Core Services Initialized.");

        // 3. DB & Repository 연결
        m_db = m_factory.CreateDatabase();
        if(IS_INVALID(m_db) || !m_db.Open(m_config.GetDatabaseName(), m_config.IsDatabaseCommon())) return false;
        
        m_repo = m_factory.CreateRepository(m_db);
        if(IS_INVALID(m_repo)) return false;
        m_globalContext.Register("repo", m_repo); // [v15.6 Fix] Watcher Discovery & Spawning dependency
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 2/6] Database Connected.");

        // 4. 세션 매니저 초기화 (동적 인스턴스 방식)
        m_sessionManager = new CXSessionManager();
        m_sessionManager.Initialize(m_repo, m_globalContext, m_factory);
        m_globalContext.Register("session_mgr", m_sessionManager);
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 3/6] Session Manager Initialized.");

        // 5. 신호 감시자 (Watcher) 초기화
        m_watcher = new CXSignalWatcher(m_repo, m_config, m_sessionManager, m_globalContext, m_factory);
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 4/6] Signal Watcher Initialized.");

        // 6. 역주입 엔진 (Sync Engine) 실행
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 5/6] Initializing Recovery Engine...");
        m_scanner = new CXTerminalScanner();
        m_injector = new CXReverseInjector(m_scanner, m_repo, m_sessionManager, m_config);
        
        // [v16.18 Paused] 역주입 기능 사용 중지 (User Request)
        /*
        if(IS_VALID(m_injector)) {
            CXParam xp;
            m_injector.Pulse(GetPointer(xp));
        }
        */

        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 6/6] System Bootstrap Complete.");
        return true;
    }

    virtual void Pulse() override {
        CXParam xp;
        
        //-- 1. 신호 감시 (Discovery & Binding)
        if(IS_VALID(m_watcher)) m_watcher.Pulse(GetPointer(xp));
        
        //-- 2. 활성 세션 구동 및 GC (Execution & Cleanup)
        if(IS_VALID(m_sessionManager)) m_sessionManager.Pulse(GetPointer(xp));

        //-- [추가] 주기적 역동기화 감시 (예: 100틱마다)
        // [v16.18 Paused] 역주입 기능 사용 중지 (User Request)
        /*
        static int tick_count = 0;
        if(++tick_count % 100 == 0 && IS_VALID(m_injector)) {
            m_injector.Pulse(GetPointer(xp));
        }
        */
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
