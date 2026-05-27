#ifndef CXSIGNALWATCHER_MQH
#define CXSIGNALWATCHER_MQH

#include "..\Platform\Core\Interfaces\IRepository.mqh"
#include "..\Platform\Core\Interfaces\ICXConfig.mqh"
#include "..\Platform\Core\Interfaces\ICXParam.mqh"
#include "..\Platform\Core\Interfaces\ICXFluentSequence.mqh"
#include "..\Platform\Core\Interfaces\ICXSessionManager.mqh"
#include "..\Platform\Core\Interfaces\ICXContext.mqh"
#include "..\Platform\Core\Interfaces\ICXServiceFactory.mqh"
#include "..\Platform\Core\Macros\CXMacros.mqh"
#include "..\Platform\Core\Sequence\CXSequenceOrchestrator.mqh"

/**
 * @class CXSignalWatcher
 * @brief DB 신호 테이블을 감시하고 적절한 세션에 할당하는 모듈 (독립 로그 지원)
 */
class CXSignalWatcher : public ICXSignalWatcher {
private:
    IRepository*            m_repo;
    ICXConfig*              m_config;
    ICXSessionManager*      m_sessionManager;
    ICXContext*             m_globalContext;
    ICXContext*             m_watcherContext; // [v15.8] Watcher Scoped Context
    ICXLogger*              m_watcherLogger;  // [v15.8] Dedicated Watcher Logger
    ICXFluentSequence*      m_sequence;
    CXSequenceOrchestrator* m_orchestrator;
    string                  m_mode;

public:
    CXSignalWatcher(IRepository* repo, ICXConfig* cfg, ICXSessionManager* pool, ICXContext* globalCtx, ICXServiceFactory* factory, string mode = "Entry") 
        : m_repo(repo), m_config(cfg), m_sessionManager(pool), m_globalContext(globalCtx), m_mode(mode) {
        
        // 1. Watcher 전용 독립 로거 생성
        m_watcherLogger = factory.CreateLogger("Watcher_" + m_mode, cfg);

        // 2. Watcher 전용 컨텍스트 구축 (전역 컨텍스트 상속)
        m_watcherContext = factory.CreateContext();
        if(IS_VALID(m_watcherContext)) {
            m_watcherContext.Register("repo", repo);
            m_watcherContext.Register("config", cfg);
            m_watcherContext.Register("session_mgr", pool);
            m_watcherContext.Register("orchestrator", globalCtx.Get("orchestrator"));
            m_watcherContext.Register("guard", globalCtx.Get("guard"));
            m_watcherContext.Register("exit_mgr", globalCtx.Get("exit_mgr"));
            m_watcherContext.Register("terminal_platform", globalCtx.Get("terminal_platform"));
            m_watcherContext.Register("db", globalCtx.Get("db")); // [Zombie Integration] Register database dependency
            m_watcherContext.Register("logger", m_watcherLogger); // 독립 로거 주입
            m_watcherContext.Register("factory", factory); // [v18.25] Register factory for dynamic stages
        }

        m_sequence = new CXFluentSequence(m_watcherContext, "Watcher" + m_mode + "Seq");
        
        // [v16.10] Dependency Injection Fix: Retrieve the correct AppOrchestrator from context
        // instead of creating a raw base CXSequenceOrchestrator.
        m_orchestrator = CX_GET_OBJ(m_globalContext, "orchestrator", CXSequenceOrchestrator);
        
        if(IS_VALID(m_orchestrator) && IS_VALID(m_sequence)) {
            // [v16.2] Dependency Injection refinement
            if(m_mode == "Exit") {
                m_orchestrator.BuildWatcherExitSequence(m_sequence);
            } else if(m_mode == "Unified") {
                m_orchestrator.BuildWatcherSequence(m_sequence);
            } else {
                m_orchestrator.BuildWatcherEntrySequence(m_sequence);
            }
            m_sequence.Build();
        }
    }

    virtual ~CXSignalWatcher() override {
        SAFE_DELETE(m_sequence);
        // m_orchestrator is owned by CXAppService/GlobalContext, do not delete here.
        SAFE_DELETE(m_watcherContext);
        SAFE_DELETE(m_watcherLogger);
    }

    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(m_sequence)) return;
        
        // [v15.9] Inject scoped context into param for isolated logging
        if(IS_VALID(xp)) {
            xp.SetContext(m_watcherContext);
            xp.SetSignal(NULL);
        }
        
        m_sequence.Pulse(xp);

        // [v15.5] Watcher Circuit Breaker: 시퀀스 에러 발생 시 상세 로깅
        if(m_sequence.State() == WATCHER_ERROR) {
            string errorDetail = (IS_VALID(xp)) ? xp.GetString() : "Unknown Watcher Error";
            string enhancedError = StringFormat("[WATCHER-FATAL] Circuit Breaker Activated. Reason: %s", errorDetail);
            
            // [v15.8] Use the scoped context's logger for fatality reporting
            ICXLogger* log = m_watcherContext.GetLogger();
            if(IS_VALID(log)) log.Error(xp, enhancedError);
            Print(enhancedError);
        }
    }
};

#endif
