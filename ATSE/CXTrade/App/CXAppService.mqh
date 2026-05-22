#ifndef CXAPPSERVICE_MQH
#define CXAPPSERVICE_MQH

#include "..\Interfaces\ICXAppService.mqh"
#include "..\Interfaces\ICXConfig.mqh"
#include "..\Interfaces\IDatabase.mqh"
#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\ICXSignalWatcher.mqh"
#include "..\Interfaces\ICXTradingSessionPool.mqh"
#include "..\Interfaces\IXGuard.mqh"

// Forward includes for implementation
#include "..\Infra\CXDatabase.mqh"
#include "..\Infra\CXSignalRepository.mqh"
#include "..\Infra\CXGuard.mqh"
#include "..\Module\CXSignalWatcher.mqh"
#include "..\Session\CXTradingSession.mqh"
#include "CXTradingSessionPool.mqh"
#include "CXServiceFactory.mqh"
#include "..\Models\CXContext.mqh"
#include "..\Infra\Sync\CXReverseInjector.mqh"

#include "..\Infra\CXSequenceOrchestrator.mqh"

class CXAppService : public ICXAppService {
private:
    ICXConfig*            m_config;
    IDatabase*            m_db;
    IRepository*          m_repo;
    ICXSignalWatcher*     m_watcher;
    ICXTradingSessionPool* m_sessionPool;
    CXReverseInjector*    m_injector;
    ICXContext*           m_globalContext;
    IXGuard*              m_guard;
    CXSequenceOrchestrator* m_orchestrator;
    ICXServiceFactory*    m_factory;
    ICXLogger*            m_logger; // 시스템 통합 로거
    CXTerminalScanner*    m_scanner;
    
public:
    CXAppService(ICXConfig* config) : m_config(config), m_db(NULL), m_repo(NULL), 
                                      m_watcher(NULL), m_sessionPool(NULL), 
                                      m_injector(NULL), m_globalContext(NULL), 
                                      m_guard(NULL), m_orchestrator(NULL), m_factory(NULL), m_logger(NULL), m_scanner(NULL) {}
    
    virtual ~CXAppService() {
        SAFE_DELETE(m_db);
        SAFE_DELETE(m_repo);
        SAFE_DELETE(m_watcher);
        SAFE_DELETE(m_injector);
        SAFE_DELETE(m_sessionPool);
        SAFE_DELETE(m_guard);
        SAFE_DELETE(m_orchestrator);
        SAFE_DELETE(m_globalContext);
        SAFE_DELETE(m_factory);
        SAFE_DELETE(m_logger);
        SAFE_DELETE(m_scanner);
    }

    /**
     * @brief Two-phase Initialization
     */
    virtual bool Initialize(int poolSize = 50) override {
        // 1. 서비스 팩토리 및 전역 컨텍스트 조기 생성
        m_factory = new CXServiceFactory();
        if(IS_INVALID(m_factory)) return false;

        m_globalContext = new CXContext("Global");
        if(IS_INVALID(m_globalContext)) return false;
        m_globalContext.Register("config", m_config);

        // 1.1 시퀀스 오케스트레이터 초기화 (모든 시퀀스 조립의 근간)
        m_orchestrator = new CXSequenceOrchestrator();
        if(IS_INVALID(m_orchestrator)) return false;
        m_globalContext.Register("orchestrator", m_orchestrator);

        // 2. 시스템 통합 로거 초기화 (SID: System)
        if(m_config.IsBootLogEnabled()) {
            m_logger = m_factory.CreateLogger("System", m_config);
            if(IS_VALID(m_logger)) {
                m_globalContext.Register("logger", m_logger);
                m_logger.Log(LOG_LVL_INFO, ">>> ATSE Framework Initializing (System SID) <<<");
            }
        }
        
        CXParam xp;
        xp.SetContext(m_globalContext);

        // 3. 가드 시스템 기동
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 1/6] Initializing Guard System...");
        m_guard = new CXGuard(m_globalContext);
        if(IS_INVALID(m_guard)) return false;
        m_globalContext.Register("guard", m_guard);

        // 4. 인프라 서비스 (DB)
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 2/6] Connecting to Database & Repository...");
        m_db = new CXDatabase();
        if(IS_INVALID(m_db)) return false;
        
        CXDatabase* db = dynamic_cast<CXDatabase*>(m_db);
        if(IS_VALID(db)) {
            if(!db.OpenByConfig(m_config)) {
                if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_ERROR, "Database open failed.");
                return false;
            }
        } else {
            if(!m_db.Open()) return false;
        }
        
        m_repo = new CXSignalRepository(m_db);
        if(IS_INVALID(m_repo)) return false;
        m_globalContext.Register("repo", m_repo);

        // 5. 세션 풀 (Session Pool)
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, StringFormat("[STEP 3/6] Initializing Session Pool (Size: %d)...", poolSize));
        m_sessionPool = new CXTradingSessionPool(poolSize);
        if(IS_INVALID(m_sessionPool)) return false;
        
        m_sessionPool.Initialize(m_repo, m_globalContext, m_factory);
        m_globalContext.Register("session_pool", m_sessionPool);

        // 6. 역주입 엔진 (Sync Engine) 실행
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 4/6] Running Cold-Boot Synchronization...");
        m_scanner = new CXTerminalScanner();
        m_injector = new CXReverseInjector(m_scanner, m_repo, m_sessionPool);
        if(IS_VALID(m_injector)) {
            m_injector.Pulse(GetPointer(xp));
        }

        // 7. 감시 엔진 (Watcher) 활성화
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_TRACE, "[STEP 5/6] Activating Signal Watcher...");
        m_watcher = new CXSignalWatcher(m_repo, m_config, m_sessionPool, m_globalContext);
        if(IS_INVALID(m_watcher)) return false;
        
        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_INFO, ">>> ATSE Framework Initialization Complete <<<");
        
        ExportSchema(); // [SSOT Bridge]
        return true;
    }
    
    /**
     * @brief [SSOT Bridge] MQL5 매크로 스키마를 JSON으로 익스포트
     */
    void ExportSchema() {
        string json = "{\n  \"fields\": [\n";
        #define X(type, name, dbType, getter) \
            json += StringFormat("    { \"name\": \"%s\", \"type\": \"%s\", \"dbType\": \"%s\", \"getter\": \"%s\" },\n", \
                                 #name, typename(type), #dbType, #getter);
        SIGNAL_SCHEMA_FIELDS
        #undef X
        
        // 마지막 쉼표 제거
        if(StringLen(json) > 3) json = StringSubstr(json, 0, StringLen(json)-2) + "\n";
        json += "  ]\n}";

        int h = FileOpen("SCHEMA.json", FILE_WRITE|FILE_TXT|FILE_COMMON|FILE_ANSI);
        if(h != INVALID_HANDLE) {
            FileWriteString(h, json);
            FileClose(h);
            if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_DEBUG, "[BRIDGE] Schema metadata exported to Common\\Files\\SCHEMA.json");
        }
    }
    
    virtual void Pulse() override {
        Pulse(EVENT_TICK);
    }

    virtual void Pulse(ENUM_CX_EVENT event) {
        CXParam xp; 
        xp.SetContext(m_globalContext);
        xp.SetEvent(event);
        
        if(IS_VALID(m_watcher)) m_watcher.Pulse(GetPointer(xp));
        if(IS_VALID(m_sessionPool)) m_sessionPool.Pulse(GetPointer(xp));

        //-- [추가] 주기적 역동기화 감시 (예: 100틱마다)
        static int tick_count = 0;
        if(++tick_count % 100 == 0 && IS_VALID(m_injector)) {
            m_injector.Pulse(GetPointer(xp));
        }
    }

    virtual void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) override {
        CXParam xp;
        xp.SetContext(m_globalContext);
        xp.SetEvent(EVENT_TRANSACTION);
        xp.SetTransaction(trans);
        
        if(IS_VALID(m_sessionPool)) m_sessionPool.Pulse(GetPointer(xp));
    }

    CXTradingSession* StartSession(ICXParam* param) {
        return (IS_VALID(m_sessionPool)) ? m_sessionPool.BorrowSession() : NULL;
    }
};

#endif
