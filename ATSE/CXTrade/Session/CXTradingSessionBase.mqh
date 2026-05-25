#ifndef CXTRADINGSESSIONBASE_MQH
#define CXTRADINGSESSIONBASE_MQH

#include "..\Core\Interfaces\IRepository.mqh"
#include "..\Core\Interfaces\ICXContext.mqh"
#include "..\Core\Interfaces\ICXFluentSequence.mqh"
#include "..\Core\Interfaces\ICXTradingSession.mqh"
#include "..\Shared\Logging\CXLogDispatcher.mqh"
#include "..\Shared\Logging\CXFileLogger.mqh"
#include "Sequence\CXSequenceOrchestrator.mqh"
#include "CXContext.mqh"
#include "Sequence\CXFluentSequence.mqh"
#include "..\Shared\Logging\CXAuditFormatter.mqh"
#include "..\Core\Interfaces\ICXServiceFactory.mqh"

/**
 * @class CXTradingSessionBase
 * @brief 모든 상태별 세션 클래스의 공통 기능을 정의하는 베이스 클래스 (v18.0)
 */
class CXTradingSessionBase : public ICXTradingSession {
protected:
    ICXContext*         m_ctx;
    IRepository*        m_repo;
    CXLogDispatcher*    m_logger;
    ICXFluentSequence*  m_sequence;
    ICXContext*         m_globalCtx;
    ICXSignal*          m_signal; 
    ICXServiceFactory*  m_factory; 
    bool                m_isActive;
    string              m_sid;

public:
    CXTradingSessionBase(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : m_repo(repo), m_globalCtx(globalCtx), m_isActive(false), m_signal(NULL), m_factory(factory), m_logger(NULL), m_ctx(NULL), m_sequence(NULL) {
    }

    virtual ~CXTradingSessionBase() {
        if(m_sid != "" && IS_VALID(m_globalCtx)) {
            m_globalCtx.RemoveChild(m_sid);
        }
        SAFE_DELETE(m_sequence); 
        SAFE_DELETE(m_logger);
        SAFE_DELETE(m_ctx);
        SAFE_DELETE(m_signal); 
    }

    virtual void Pulse(ICXParam* xp) override {
        if(IS_INVALID(xp)) return;
        if(!m_isActive && xp.GetEvent() != EVENT_START && xp.GetEvent() != EVENT_INJECT) return;

        ICXSignal* sig = xp.GetSignal();
        if(IS_VALID(sig)) {
            string incomingSid = sig.GetSid();
            if(m_sid == "") m_sid = incomingSid;
            if(m_signal == NULL) m_signal = sig;
            if(incomingSid != m_sid) return;
        } else if(m_signal != NULL) {
            xp.SetSignal(m_signal);
            sig = m_signal;
        }

        if(IS_VALID(m_ctx)) {
            xp.SetContext(m_ctx);
            m_ctx.SetParam(xp);
        }

        if(IS_VALID(m_sequence)) {
            m_sequence.Pulse(xp);
            HandleSequenceResult(xp, sig);
        }
    }

    virtual void Start(ICXParam* xp) override {
        m_isActive = true;
        if(m_sid != "" && IS_VALID(m_globalCtx)) m_globalCtx.AddChild(m_sid, m_ctx);
        if(IS_VALID(m_sequence)) m_sequence.ResetState();
        xp.SetEvent(EVENT_START);
        Pulse(xp);
    }

    virtual void InjectState(CXSignal* sig) override {
        m_isActive = true;
        if(m_sid != "" && IS_VALID(m_globalCtx)) m_globalCtx.AddChild(m_sid, m_ctx);
        CXParam xp;
        xp.SetSignal(sig);
        xp.SetEvent(EVENT_INJECT);
        Pulse(GetPointer(xp));
    }

    virtual void ForceTransition(int state) override {
        if(!m_isActive || IS_INVALID(m_sequence)) return;
        if(m_sequence.State() == state || m_sequence.State() >= SESSION_CLOSED) return;
        m_sequence.ForceState(state);
    }

    virtual bool IsActive() const override { return m_isActive; }
    virtual string GetSid() const override { return m_sid; }

protected:
    virtual void HandleSequenceResult(ICXParam* xp, ICXSignal* sig) {
        if(m_sequence.State() == SESSION_ERROR) {
            string errorDetail = xp.GetString(); 
            if(errorDetail == "" && IS_VALID(sig)) errorDetail = sig.GetStatusMsg();
            string enhancedError = StringFormat("Circuit Breaker Activated. Reason: %s", errorDetail);
            XP_LOG_ERROR(xp, CXAuditFormatter::Build("SESSION-ERROR", xp, enhancedError));
            if(IS_VALID(sig)) {
                CXMessageProvider::UpdateStatus(sig, XE_ERROR, enhancedError);
                if(IS_VALID(m_repo)) m_repo.UpdateStatus(sig);
            }
            m_isActive = false;
        }
    }

    void InitBase(ICXServiceFactory* factory) {
        if(IS_INVALID(factory)) return;
        m_ctx = factory.CreateContext();
        if(IS_INVALID(m_ctx)) return;

        if(IS_VALID(m_globalCtx)) {
            m_ctx.Register("guard", m_globalCtx.Get("guard"));
            m_ctx.Register("config", m_globalCtx.Get("config"));
            m_ctx.Register("logger", m_globalCtx.Get("logger"));
            m_ctx.Register("orchestrator", m_globalCtx.Get("orchestrator"));
        }
        m_ctx.Register("repo", m_repo);
        
        m_sequence = factory.CreateSequence(m_ctx, "SessionSeq");
        if(IS_VALID(m_sequence)) {
            CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(m_ctx, "orchestrator", CXSequenceOrchestrator);
            if(IS_VALID(orchestrator)) orchestrator.BuildSessionSequence(CX_CAST(CXFluentSequence, m_sequence));
            m_sequence.Build();
        }
        m_isActive = true;
    }
};

#endif
