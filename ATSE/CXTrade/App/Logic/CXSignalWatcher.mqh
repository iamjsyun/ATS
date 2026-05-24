#ifndef CXSIGNALWATCHER_MQH
#define CXSIGNALWATCHER_MQH

#include "..\..\Core\Interfaces\IRepository.mqh"
#include "..\..\Core\Interfaces\ICXConfig.mqh"
#include "..\..\Core\Interfaces\ICXParam.mqh"
#include "..\..\Core\Interfaces\ICXFluentSequence.mqh"
#include "..\..\Core\Interfaces\ICXSessionManager.mqh"
#include "..\..\Core\Interfaces\ICXContext.mqh"
#include "..\..\Core\Macros\CXMacros.mqh"
#include "..\..\Session\Sequence\CXSequenceOrchestrator.mqh"

/**
 * @class CXSignalWatcher
 * @brief DB 신호 테이블을 감시하고 적절한 세션에 할당하는 모듈
 */
class CXSignalWatcher : public ICXSignalWatcher {
private:
    IRepository*            m_repo;
    ICXConfig*              m_config;
    ICXSessionManager*      m_sessionManager;
    ICXContext*             m_globalContext;
    ICXFluentSequence*      m_sequence;
    CXSequenceOrchestrator* m_orchestrator;

public:
    CXSignalWatcher(IRepository* repo, ICXConfig* cfg, ICXSessionManager* pool, ICXContext* globalCtx) 
        : m_repo(repo), m_config(cfg), m_sessionManager(pool), m_globalContext(globalCtx) {
        m_orchestrator = new CXSequenceOrchestrator();
        m_sequence = new CXFluentSequence(m_globalContext, "WatcherSeq");
        if(IS_VALID(m_orchestrator) && IS_VALID(m_sequence)) {
            m_orchestrator.BuildWatcherSequence(m_sequence);
            m_sequence.Build();
        }
    }

    virtual ~CXSignalWatcher() override {
        SAFE_DELETE(m_sequence);
        SAFE_DELETE(m_orchestrator);
    }

    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(m_sequence)) return;
        if(IS_VALID(xp)) xp.SetSignal(NULL);
        m_sequence.Pulse(xp);
    }
};

#endif
