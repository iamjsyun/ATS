#ifndef CXSIGNALWATCHER_MQH
#define CXSIGNALWATCHER_MQH

#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\ICXConfig.mqh"
#include "..\Interfaces\ICXParam.mqh"
#include "..\Interfaces\ICXFluentSequence.mqh"
#include "..\Interfaces\ICXTradingSessionPool.mqh"
#include "..\Interfaces\ICXContext.mqh"
#include "..\Interfaces\CXMacros.mqh"
#include "..\Infra\CXSequenceOrchestrator.mqh"

/**
 * @class CXSignalWatcher
 * @brief DB 신호 테이블을 감시하고 적절한 세션에 할당하는 모듈
 */
class CXSignalWatcher : public ICXSignalWatcher {
private:
    IRepository*            m_repo;
    ICXConfig*              m_config;
    ICXTradingSessionPool*  m_sessionPool;
    ICXContext*             m_globalContext;
    ICXFluentSequence*      m_sequence;
    CXSequenceOrchestrator* m_orchestrator;

public:
    CXSignalWatcher(IRepository* repo, ICXConfig* cfg, ICXTradingSessionPool* pool, ICXContext* globalCtx) 
        : m_repo(repo), m_config(cfg), m_sessionPool(pool), m_globalContext(globalCtx) {
        
        m_orchestrator = new CXSequenceOrchestrator();
        m_sequence = new CXFluentSequence(globalCtx, "WatcherSeq");
        if(IS_VALID(m_orchestrator) && IS_VALID(m_sequence)) {
            m_orchestrator.BuildWatcherSequence(m_sequence);
            m_sequence.Build();
        }
    }

    virtual ~CXSignalWatcher() override {
        SAFE_DELETE(m_sequence);
        SAFE_DELETE(m_orchestrator);
    }

    /**
     * @brief 주기적 감시 실행 (Pulse)
     */
    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(m_sequence)) return;

        // [v11.1 Fix] Clear stale signal reference before discovery to prevent Sandbox Violation
        if(IS_VALID(xp)) xp.SetSignal(NULL);

        //-- [v10.16] Enforce 0.5s Pulse
        m_sequence.Pulse(xp);
    }
};

#endif
