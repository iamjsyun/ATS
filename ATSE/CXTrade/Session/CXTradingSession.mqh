#ifndef CXTRADINGSESSION_MQH
#define CXTRADINGSESSION_MQH

#include "..\Interfaces\IRepository.mqh"
#include "..\Interfaces\ICXContext.mqh"
#include "..\Interfaces\ICXFluentSequence.mqh"
#include "..\Interfaces\ICXTradingSession.mqh"
#include "..\Module\CXLogDispatcher.mqh"
#include "..\Infra\CXFileLogger.mqh"
#include "..\Models\CXContext.mqh"
#include "..\Infra\CXFluentSequence.mqh"

#include "..\Interfaces\IXEntryManager.mqh"
#include "..\Interfaces\IXOrderManager.mqh"
#include "..\Interfaces\IXPositionManager.mqh"
#include "..\Interfaces\IXExitManager.mqh"
#include "..\Interfaces\IXPriceTracker.mqh"
#include "..\Interfaces\ICXPriceManager.mqh"
#include "..\Interfaces\ICXServiceFactory.mqh"

#include "Steps\CXCompositeStep.mqh"
#include "Tasks\EntryTasks.mqh"
#include "Tasks\PendingTasks.mqh"
#include "Tasks\ActiveTasks.mqh"
#include "Tasks\ExitTasks.mqh"

#include "Steps\Exit\CXStepExitTicket.mqh"
#include "Steps\Exit\CXStepExitSweep.mqh"
#include "Steps\Exit\CXStepExitVerify.mqh"


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

        // 1. 세션 활성화 상태 및 이벤트 타입 체크
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
            
            // [v7.9 Error Recovery] 회로 차단기 등 치명적 에러 발생 시 처리
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
        InitLogger(m_sid, factory);
        xp.SetEvent(EVENT_START);
        Pulse(xp);
    }

    void Start(ICXParam* xp) {
        m_isActive = true;
        m_signal = (IS_VALID(xp)) ? xp.GetSignal() : NULL;
        m_sid = (IS_VALID(m_signal)) ? m_signal.GetSid() : "";
        xp.SetEvent(EVENT_START);
        Pulse(xp);
    }

    void InjectState(CXSignal* sig) {
        m_isActive = true;
        m_signal = sig;
        m_sid = IS_VALID(sig) ? sig.GetSid() : "";
        CXParam xp;
        xp.SetSignal(sig);
        xp.SetEvent(EVENT_INJECT);
        Pulse(GetPointer(xp));
    }

    void Reset() {
        m_isActive = false;
        m_sid = "";
        SAFE_DELETE(m_signal); //-- [v10.7 Fix] Clear ownership
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
            m_ctx.Register("logger", m_globalCtx.Get("logger")); // 초기 조립 로그용 (System Logger)
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
        
        m_ctx.Register("entry_mgr", m_entryMgr); 
        m_ctx.Register("order_mgr", m_orderMgr);
        m_ctx.Register("pos_mgr", m_posMgr);     
        m_ctx.Register("exit_mgr", m_exitMgr);
        m_ctx.Register("price_tracker", m_priceTracker);
        m_ctx.Register("price_mgr", m_priceManager);

        m_sequence = factory.CreateSequence(m_ctx, "SessionSeq");
        if(IS_INVALID(m_sequence)) return;

        InitSequence();
        
        m_isActive = true; //-- [Warm-up Fix] 생성 시 즉시 활성화 (Pool에서 관리됨)
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

        // 로그 출력을 위한 임시 파라미터 (Context 연결 필수)
        CXParam xp;
        xp.SetContext(m_ctx);

        XP_LOG_TRACE(GetPointer(xp), "Assembling Hyper-Atomized Sequence Architecture...");

        //-- 1. 진입 파이프라인 (Entry Pipeline) - Hyper-Atomized (L-G-G-P-R -> V-V-V -> V-P)
        
        //-- [1.1] Entry: Logic & Request -> Transit
        CXCompositeStep* entryStep_L = new CXCompositeStep("Step_Entry_Logic");
        entryStep_L.AddTask(new CXTaskEntry_L_Validate())
                 .AddTask(new CXTaskGuard_V_Spread())
                 .AddTask(new CXTaskGuard_V_Volatility())
                 .AddTask(new CXTaskEntry_P_Lock())
                 .AddTask(new CXTaskEntry_R_Order()); // Returns STATE_ENTRY_TRANSIT

        seq.From(SESSION_READY).Execute(entryStep_L)
           .OnSuccess(STATE_ENTRY_TRANSIT)
           .OnFail(SESSION_ERROR)
           .Case(SESSION_ACTIVE, SESSION_ACTIVE)
           .Case(SESSION_LIQUIDATING, SESSION_LIQUIDATING)
           .Timeout(300);

        //-- [1.2] Entry: Transit & Terminal Verify -> Verify Ready
        CXCompositeStep* entryStep_V = new CXCompositeStep("Step_Entry_Transit");
        entryStep_V.AddTask(new CXTaskEntry_V_Error())
                 .AddTask(new CXTaskEntry_V_Ticket())
                 .AddTask(new CXTaskEntry_V_Real()); // Returns STATE_ENTRY_VERIFY

        seq.From(STATE_ENTRY_TRANSIT).Execute(entryStep_V)
           .OnSuccess(STATE_ENTRY_VERIFY)
           .OnFail(SESSION_ERROR)
           .Case(SESSION_LIQUIDATING, SESSION_LIQUIDATING)
           .Timeout(60);

        //-- [1.3] Entry: DoubleCheck & Persistence -> Active/Trailing
        CXCompositeStep* entryStep_P = new CXCompositeStep("Step_Entry_Verify");
        entryStep_P.AddTask(new CXTaskFinalize_V_DoubleCheck())
                 .AddTask(new CXTaskEntry_P_Finalize()); // Returns SESSION_ACTIVE or STATE_ENTRY_TRAILING

        seq.From(STATE_ENTRY_VERIFY).Execute(entryStep_P)
           .OnFail(SESSION_ERROR)
           .Case(SESSION_LIQUIDATING, SESSION_LIQUIDATING)
           .Timeout(30);

        //-- 2. 대기 파이프라인 (Pending Pipeline)
        CXCompositeStep* pendingStep = new CXCompositeStep("Step_PendingComposite");
        pendingStep.AddTask(new CXTaskPending_V_Sync())
                   .AddTask(new CXTaskPending_L_Rebound())
                   .AddTask(new CXTaskPending_L_Improve())
                   .AddTask(new CXTaskPending_R_Apply());

        seq.From(STATE_ENTRY_TRAILING).Execute(pendingStep)
           .OnSuccess(SESSION_ACTIVE)
           .OnFail(SESSION_ERROR)
           .Case(SESSION_LIQUIDATING, SESSION_LIQUIDATING)
           .Timeout(3600);

        //-- 3. 활성 파이프라인 (Monitoring & TS)
        CXCompositeStep* activeStep = new CXCompositeStep("Step_ActiveComposite");
        activeStep.AddTask(new CXTaskComm_V_Status())
                  .AddTask(new CXTaskSync_V_Stale())
                  .AddTask(new CXTaskActive_V_Terminal())
                  .AddTask(new CXTaskActive_P_Align())
                  .AddTask(new CXTaskActive_L_Status())
                  .AddTask(new CXTaskIntentWatch())
                  .AddTask(new CXTaskAlphaCalc())
                  .AddTask(new CXTaskAlphaApply());

        seq.From(SESSION_ACTIVE).Execute(activeStep)
           .Case(SESSION_LIQUIDATING, SESSION_LIQUIDATING)
           .Timeout(72000); 

        //-- 4. 청산 파이프라인 (Liquidation Pipeline) - Hyper-Atomized (L-P-R -> V-V -> P)
        
        //-- [4.1] Exit: Logic & Request -> Transit
        CXCompositeStep* exitStep_L = new CXCompositeStep("Step_Exit_Logic");
        exitStep_L.AddTask(new CXTaskExit_L_Prepare())
                .AddTask(new CXTaskExit_P_Lock())
                .AddTask(new CXTaskExit_R_Order()); // Returns STATE_LIQUIDATING_TRANSIT

        seq.From(SESSION_LIQUIDATING).Execute(exitStep_L)
           .OnSuccess(STATE_LIQUIDATING_TRANSIT)
           .OnFail(SESSION_ERROR)
           .Timeout(300)
           .Retries(3);

        //-- [4.2] Exit: Transit & Terminal Verify -> Verify Ready
        CXCompositeStep* exitStep_V = new CXCompositeStep("Step_Exit_Transit");
        exitStep_V.AddTask(new CXTaskExit_V_Error())
                .AddTask(new CXTaskExit_V_Terminal()); // Returns STATE_EXIT_VERIFY

        seq.From(STATE_LIQUIDATING_TRANSIT).Execute(exitStep_V)
           .OnSuccess(STATE_EXIT_VERIFY)
           .OnFail(SESSION_ERROR)
           .Timeout(60);

        //-- [4.3] Exit: Persistence -> Closed
        CXCompositeStep* exitStep_P = new CXCompositeStep("Step_Exit_Verify");
        exitStep_P.AddTask(new CXTaskExit_P_Finalize()); // Returns SESSION_CLOSED

        seq.From(STATE_EXIT_VERIFY).Execute(exitStep_P)
           .OnSuccess(SESSION_CLOSED)
           .OnFail(SESSION_ERROR)
           .Timeout(30);
        
        seq.Build();
        
        //-- [v10.2] Detailed Assembly Report
        string info = StringFormat("Sequence Assembly Complete: [Name:%s] [Nodes:%d] [States:{%s}]", 
                                   seq.GetSequenceName(), seq.GetNodeCount(), seq.GetStateSummary());
        XP_LOG_INFO(GetPointer(xp), info);
    }
};

#endif
#endif
           .Timeout(30);
        
        seq.Build();
        
        //-- [v10.2] Detailed Assembly Report
        string info = StringFormat("Sequence Assembly Complete: [Name:%s] [Nodes:%d] [States:{%s}]", 
                                   seq.GetSequenceName(), seq.GetNodeCount(), seq.GetStateSummary());
        XP_LOG_INFO(GetPointer(xp), info);
    }
};

#endif
