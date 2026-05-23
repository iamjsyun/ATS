#ifndef CXTRADINGSESSION_MQH
#define CXTRADINGSESSION_MQH

#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\ICXContext.mqh"
#include "..\Interfaces\ICXFluentSequence.mqh"
#include "..\Interfaces\ICXTradingSession.mqh"
#include "..\Module\CXLogDispatcher.mqh"
#include "..\Infra\CXFileLogger.mqh"
#include "..\Infra\CXSequenceOrchestrator.mqh"
#include "..\Models\CXContext.mqh"
#include "..\Infra\CXFluentSequence.mqh"

#include "..\Interfaces\IXEntryManager.mqh"
#include "..\Interfaces\IXOrderManager.mqh"
#include "..\Interfaces\IXPositionManager.mqh"
#include "..\Interfaces\IXExitManager.mqh"
#include "..\Interfaces\IXPriceTracker.mqh"
#include "..\Interfaces\ICXPriceManager.mqh"
#include "..\Interfaces\ICXRiskManager.mqh"
#include "..\Interfaces\ICXSymbolManager.mqh"
#include "..\Interfaces\ICXInventoryManager.mqh"
#include "..\Interfaces\ICXServiceFactory.mqh"

/**
 * @class CXTradingSession
 * @brief 독립적인 샌드박스 실행 단위 (Sandboxed Execution Unit)
 */
class CXTradingSession : public ICXTradingSession {
private:
    ICXContext*         m_ctx;
    IRepository*        m_repo;
    CXLogDispatcher*    m_logger;
    ICXFluentSequence*  m_sequence;
    ICXContext*         m_globalCtx;
    ICXSignal*          m_signal; //-- [v10.6] Persisted Signal Reference
    bool                m_isActive;
    string              m_sid;

    //-- Managers & Services
    IXEntryManager*    m_entryMgr;
    IXOrderManager*    m_orderMgr;
    IXPositionManager* m_posMgr;
    IXExitManager*     m_exitMgr;
    IXPriceTracker*    m_priceTracker;
    ICXPriceManager*   m_priceManager;
    ICXRiskManager*    m_riskManager;
    ICXSymbolManager*  m_symbolManager;
    ICXInventoryManager* m_inventoryManager;

public:
    CXTradingSession(IRepository* repo, ICXContext* globalCtx, ICXServiceFactory* factory) 
        : m_repo(repo), m_globalCtx(globalCtx), m_isActive(false), m_signal(NULL) {
        Bootstrap(factory);
    }

    ~CXTradingSession() {
        SAFE_DELETE(m_entryMgr); SAFE_DELETE(m_orderMgr);
        SAFE_DELETE(m_posMgr);   SAFE_DELETE(m_exitMgr);
        SAFE_DELETE(m_priceTracker);
        SAFE_DELETE(m_priceManager);
        SAFE_DELETE(m_riskManager);
        SAFE_DELETE(m_symbolManager);
        SAFE_DELETE(m_inventoryManager);
        SAFE_DELETE(m_sequence); SAFE_DELETE(m_logger);
        SAFE_DELETE(m_ctx);
        SAFE_DELETE(m_signal); //-- [v10.7 Fix] Cleanup signal on destruction
    }

    /**
     * @brief 통합 이벤트 수신 및 시퀀스 구동
     */
    void Pulse(ICXParam* xp) {
        if(IS_INVALID(xp)) return;

        // 1. 세션 활성화 상태 및 이벤트에 대한 체크
        if(!m_isActive && xp.GetEvent() != EVENT_START && xp.GetEvent() != EVENT_INJECT) {
            return;
        }

        // 2. [SANDBOX GUARD] SID 및 Signal 컨텍스트 보정
        ICXSignal* sig = xp.GetSignal();
        if(IS_VALID(sig)) {
            string incomingSid = sig.GetSid();
            
            if(m_sid == "") m_sid = incomingSid;
            if(m_signal == NULL) m_signal = sig;
            
            if(incomingSid != m_sid) {
                PrintFormat("[SANDBOX-VIOLATION] Session SID(%s) received mismatching Signal SID(%s). Execution blocked.", m_sid, incomingSid);
                return;
            }
        } else if(m_signal != NULL) {
            //-- [v10.6 Fix] xp에 Signal이 없으면 저장된 참조 주입 (연속 실행 보장)
            xp.SetSignal(m_signal);
            sig = m_signal;
        }

        // 2.1 [v10.7 Fix] Transaction Filtering (Anti Cross-talk)
        if(xp.GetEvent() == EVENT_TRANSACTION) {
            CXParam* px = dynamic_cast<CXParam*>(xp);
            if(IS_VALID(px) && IS_VALID(sig)) {
                MqlTradeTransaction trans = px.GetTransaction();
                //-- 본인 티켓과 관련 없는 트랜잭션은 무시
                if(trans.order != sig.GetTicket() && trans.position != sig.GetTicket()) {
                    return;
                }
                XP_LOG_TRACE(xp, StringFormat("[SESSION-TX] Correlated Transaction Found for Ticket:%I64u", sig.GetTicket()));
            }
        }

        // 3. 시퀀스 엔진 구동
        if(IS_VALID(m_sequence)) {
            m_sequence.Pulse(xp);
            
            // [v7.9 Error Recovery] 회로 차단기 및 치명적 에러 발생 시 처리
            if(m_sequence.State() == SESSION_ERROR) {
                string errorDetail = ""; 
                // 시퀀스 내에서 발생한 마지막 에러 메시지 추출 시도
                errorDetail = xp.GetString(); 
                if(errorDetail == "") errorDetail = "Unknown Sequence Interruption";

                // [v10.33] 명시적 Circuit Breaker 메시지 생성
                string finalMsg = StringFormat("[ERR-000] Circuit Breaker Tripped: %s. Session terminated for system safety.", errorDetail);
                
                XP_LOG_ERROR(xp, finalMsg);
                if(IS_VALID(sig)) {
                    CXMessageProvider::UpdateStatus(sig, XE_ERROR, finalMsg);
                    if(IS_VALID(m_repo)) m_repo.UpdateStatus(sig);
                }
                m_isActive = false; // 세션 영구 비활성화 (좀비 방지)
            }
        }
    }

    void Start(ICXParam* xp, ICXServiceFactory* factory) {
        m_isActive = true;
        m_signal = (IS_VALID(xp)) ? xp.GetSignal() : NULL;
        m_sid = (IS_VALID(m_signal)) ? m_signal.GetSid() : "";
        
        //--- [SSOC] 글로벌 트리에 등록
        if(m_sid != "" && IS_VALID(m_globalCtx)) {
            m_globalCtx.AddChild(m_sid, m_ctx);
        }

        InitLogger(m_sid, factory);
        xp.SetEvent(EVENT_START);
        Pulse(xp);
    }

    void Start(ICXParam* xp) {
        m_isActive = true;
        m_signal = (IS_VALID(xp)) ? xp.GetSignal() : NULL;
        m_sid = (IS_VALID(m_signal)) ? m_signal.GetSid() : "";

        //--- [SSOC] 글로벌 트리에 등록
        if(m_sid != "" && IS_VALID(m_globalCtx)) {
            m_globalCtx.AddChild(m_sid, m_ctx);
        }

        xp.SetEvent(EVENT_START);
        Pulse(xp);
    }

    void InjectState(CXSignal* sig) {
        m_isActive = true;
        m_signal = sig;
        m_sid = IS_VALID(sig) ? sig.GetSid() : "";

        //--- [SSOC] 글로벌 트리에 등록
        if(m_sid != "" && IS_VALID(m_globalCtx)) {
            m_globalCtx.AddChild(m_sid, m_ctx);
        }

        CXParam xp;
        xp.SetSignal(sig);
        xp.SetEvent(EVENT_INJECT);
        Pulse(GetPointer(xp));
    }

    /**
     * @brief [v14.3] 외부 강제 상태 전이 (Interruption)
     */
    virtual void ForceTransition(int state) override {
        if(!m_isActive || IS_INVALID(m_sequence)) return;
        
        // [v14.5 Guard] 이미 해당 상태거나 종료 상태면 무시
        if(m_sequence.State() == state || m_sequence.State() >= SESSION_CLOSED) return;

        XP_LOG_WARN(NULL, StringFormat("[SESSION-INTERRUPT] Force Transition Triggered: %d -> %d for SID:%s", 
                                       m_sequence.State(), state, m_sid));
        m_sequence.ForceState(state);
    }

    void Reset() {
        if(!m_isActive && m_sid == "") return;

        //--- [SSOC] 글로벌 트리에서 제거
        if(m_sid != "" && IS_VALID(m_globalCtx)) {
            m_globalCtx.AddChild(m_sid, NULL); 
        }

        XP_LOG_INFO(NULL, StringFormat("[SESSION-RESET] Releasing Session for SID:%s", m_sid));

        m_isActive = false;
        m_sid = "";
        SAFE_DELETE(m_signal); 
        if(IS_VALID(m_sequence)) m_sequence.ForceState(SESSION_READY);
    }

    bool IsActive() const { return m_isActive; }
    virtual string GetSid() const override { return m_sid; }

private:
    void Bootstrap(ICXServiceFactory* factory) {
        if(IS_INVALID(factory)) return;

        m_ctx = factory.CreateContext();
        if(IS_INVALID(m_ctx)) return;

        // 글로벌 서비스 상속 (Guard, Config, Logger 등)
        if(IS_VALID(m_globalCtx)) {
            m_ctx.Register("guard", m_globalCtx.Get("guard"));
            m_ctx.Register("config", m_globalCtx.Get("config"));
            m_ctx.Register("logger", m_globalCtx.Get("logger"));
            m_ctx.Register("orchestrator", m_globalCtx.Get("orchestrator"));
        }

        m_ctx.Register("repo", m_repo);

        m_entryMgr = factory.CreateEntryManager(m_ctx);
        if(IS_INVALID(m_entryMgr)) return;

        m_orderMgr = factory.CreateOrderManager(m_ctx);
        if(IS_INVALID(m_orderMgr)) return;

        m_posMgr   = factory.CreatePositionManager(m_ctx);
        if(IS_INVALID(m_posMgr)) return;

        m_exitMgr  = factory.CreateExitManager(m_ctx);
        if(IS_INVALID(m_exitMgr)) return;

        m_priceTracker = factory.CreatePriceTracker(m_ctx);
        if(IS_INVALID(m_priceTracker)) return;

        m_priceManager = factory.CreatePriceManager(m_ctx);
        if(IS_INVALID(m_priceManager)) return;

        m_riskManager = factory.CreateRiskManager(m_ctx);
        if(IS_INVALID(m_riskManager)) return;

        m_symbolManager = factory.CreateSymbolManager(m_ctx);
        if(IS_INVALID(m_symbolManager)) return;

        m_inventoryManager = factory.CreateInventoryManager(m_ctx);
        if(IS_INVALID(m_inventoryManager)) return;
        
        m_ctx.Register("entry_mgr", m_entryMgr); 
        m_ctx.Register("order_mgr", m_orderMgr);
        m_ctx.Register("pos_mgr", m_posMgr);     
        m_ctx.Register("exit_mgr", m_exitMgr);
        m_ctx.Register("price_tracker", m_priceTracker);
        m_ctx.Register("price_mgr", m_priceManager);
        m_ctx.Register("risk_mgr", m_riskManager);
        m_ctx.Register("sym_mgr", m_symbolManager);
        m_ctx.Register("inventory_mgr", m_inventoryManager);

        m_sequence = factory.CreateSequence(m_ctx, "SessionSeq");
        if(IS_INVALID(m_sequence)) return;

        InitSequence();
        
        m_isActive = true; 
    }

    void InitLogger(string sid, ICXServiceFactory* factory) {
        if(IS_INVALID(factory)) return;
        
        ICXConfig* config = NULL;
        if(IS_VALID(m_ctx)) config = dynamic_cast<ICXConfig*>(m_ctx.Get("config"));
        
        m_logger = dynamic_cast<CXLogDispatcher*>(factory.CreateLogger(sid, config));
        if(IS_VALID(m_logger)) {
            m_ctx.Register("logger", m_logger);
        }
    }

    void InitSequence() {
        CXFluentSequence* seq = dynamic_cast<CXFluentSequence*>(m_sequence);
        if(IS_INVALID(seq)) return;

        //--- [Orchestration] 시퀀스 조립 위임
        CXSequenceOrchestrator* orchestrator = CX_GET_OBJ(m_ctx, "orchestrator", CXSequenceOrchestrator);
        if(IS_VALID(orchestrator)) {
            orchestrator.BuildSessionSequence(seq);
        }
        
        //-- [v10.2] Detailed Assembly Report
        string info = StringFormat("Sequence Assembly Complete: [Name:%s] [Nodes:%d] [States:{%s}]", 
                                   seq.GetSequenceName(), seq.GetNodeCount(), seq.GetStateSummary());
        
        ICXLogger* log = CX_GET_OBJ(m_ctx, "logger", ICXLogger);
        if(IS_VALID(log)) log.Info(NULL, info);
    }
};

#endif
