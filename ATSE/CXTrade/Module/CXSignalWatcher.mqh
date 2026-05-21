#ifndef CXSIGNALWATCHER_MQH
#define CXSIGNALWATCHER_MQH

#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\ICXConfig.mqh"
#include "..\Interfaces\ICXParam.mqh"
#include "..\Interfaces\ICXFluentSequence.mqh"
#include "..\Interfaces\CXMacros.mqh"
#include "CXLogDispatcher.mqh"
#include "..\Infra\CXFileLogger.mqh"
#include "..\Infra\CXTabLogger.mqh"
#include "..\Infra\CXRemoteLogger.mqh"
#include "..\Infra\CXFluentSequence.mqh"
#include "..\Models\CXContext.mqh"

#include "Steps\Watcher\CXStepDiscovery.mqh"
#include "Steps\Watcher\CXStepValidation.mqh"
#include "Steps\Watcher\CXStepBinding.mqh"

#include "..\Interfaces\ICXSignalWatcher.mqh"

/**
 * @class CXSignalWatcher
 * @brief ?�규 ?�호 감시 ?�퀀???�합 관�??�당
 */
class CXSignalWatcher : public ICXSignalWatcher {
private:
    IRepository*        m_repo;
    ICXConfig*          m_config;
    ICXContext*         m_ctx;
    ICXFluentSequence*  m_sequence;
    CXLogDispatcher*    m_logger; // 멀??채널 로거

    //-- [Adaptive Log]
    int                 m_pulse_count;
    int                 m_current_interval_min;
    datetime            m_last_pulse_time;
    int                 m_last_active_count; 
    string              m_last_processed_sid; //-- [v11.0] Track last processed signal to prevent spam

public:
    CXSignalWatcher(IRepository* repo, ICXConfig* config, ICXTradingSessionPool* pool, ICXContext* globalCtx) 
        : m_repo(repo), m_config(config), m_pulse_count(0), m_current_interval_min(0), m_last_pulse_time(0), m_last_active_count(-1), m_last_processed_sid("") {

        m_ctx = new CXContext();
        if(IS_INVALID(m_ctx)) return;

        //-- [Inherit] 전역 서비스 상속 (Guard 등)
        if(IS_VALID(globalCtx)) {
            m_ctx.Register("guard", globalCtx.Get("guard"));
        }

        //-- [Fix] 시퀀스 로깅 및 시스템 파라미터 연동을 위한 전용 Param 생성
        CXParam* sysParam = new CXParam();
        sysParam.SetContext(m_ctx);
        m_ctx.SetParam(CX_CAST(ICXParam, sysParam));

        m_ctx.Set("repo", m_repo);
        m_ctx.Set("config", m_config);
        m_ctx.Set("session_pool", pool);

        m_logger = new CXLogDispatcher();
        if(IS_INVALID(m_logger)) return;
        m_logger.SetConfig(m_config);

        // 1. Watcher ?�용 로그 ?�일 초기??
        CXFileLogger* fileLog = new CXFileLogger();
        if(IS_VALID(fileLog)) {
            if(fileLog.Init("SignalWatcher")) {
                m_logger.SetFileLogger(fileLog);
            } else {
                SAFE_DELETE(fileLog);
            }
        }

        // 2. ?��?????출력
        m_logger.SetTabLogger(new CXTabLogger());
// 3. ?�격 로깅 (Log4View)
if(IS_VALID(m_config) && m_config.IsWatcherRemoteLogEnabled()) {
    string host = m_config.GetRemoteLogHost();
    int port = m_config.GetRemoteLogPort();
    if(host != "" && port > 0) {
        m_logger.SetRemoteLogger(new CXRemoteLogger("Watcher", host, port, m_logger.GetFileLogger()));
    }
}


        m_ctx.Set("logger", m_logger);

        m_sequence = new CXFluentSequence(m_ctx, "WatcherSeq");
        if(IS_INVALID(m_sequence)) return;

        InitSequence();

        if(IS_VALID(m_logger)) m_logger.Log(LOG_LVL_INFO, ">>> Signal Watcher Started <<<");
    }

    ~CXSignalWatcher() {
        SAFE_DELETE(m_sequence);
        SAFE_DELETE(m_logger);
        SAFE_DELETE(m_ctx);
    }

    /**
     * @brief 주기적인 신호 감시 시퀀스 구동
     */
    virtual void Pulse(ICXParam* xp) {
        if(IS_INVALID(m_sequence)) return;

        // [v11.1 Fix] Clear stale signal reference before discovery to prevent Sandbox Violation
        if(IS_VALID(xp)) xp.SetSignal(NULL);

        //-- [v10.16] Enforce 0.5s Pulse
        m_sequence.Pulse(xp);
    }

private:
    void InitSequence() {
        CXFluentSequence* seq = CX_CAST(CXFluentSequence, m_sequence);
        if(IS_INVALID(seq)) return;

        //-- Watcher ?�퀀???�의: Discovery -> Validation -> Binding
        seq.From(WATCHER_DISCOVERY).Execute(new CXStepDiscovery()).OnSuccess(WATCHER_VALIDATION);
        seq.From(WATCHER_VALIDATION).Execute(new CXStepValidation()).OnSuccess(WATCHER_BINDING).OnFail(WATCHER_DISCOVERY);
        seq.From(WATCHER_BINDING).Execute(new CXStepBinding()).OnSuccess(WATCHER_DISCOVERY);

        seq.Build();
    }
};

#endif

