//+------------------------------------------------------------------+
//|                                           CXScenarioRunner.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//| [v1.1] TCL-based Deterministic E2E Test Runner for ATSE          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://github.com/google-gemini/gemini-cli"
#property version   "2.10"
#property strict

//--- Include test engine & mocks
#include "Scenarios\CXTclParser.mqh"
#include "Scenarios\CXVirtualPricer.mqh"
#include "Mocks\MockPriceManager.mqh"
#include "Mocks\MockTerminalPlatform.mqh"
#include "Mocks\CXTestServiceFactory.mqh"

//--- Include core ATSE files
#include "..\CXTrade\App\CXAppService.mqh"
#include "..\CXTrade\Platform\Core\Models\CXConfig.mqh"
#include "..\CXTrade\Platform\Shared\Database\CXDatabase.mqh"
#include "..\CXTrade\Platform\Shared\Database\CXSignalRepository.mqh"
#include "..\CXTrade\Platform\Core\Interfaces\ICXAssetManager.mqh"

//--- [Inputs]
input string InpScenarioFile  = "ATSE\\test_golden_path.tcl"; // TCL Filename (MQL5/Files)
input string InpDatabaseName  = "ATS_TEST.db";                // [v19.41] Isolated Test Database
input bool   InpUseCommonPath = true;                         // DB Path

//--- Global Instances
CXTclScenario*        g_scenario = NULL;
CXVirtualPricer*      g_pricer = NULL;
MockPriceManager*     g_mockPriceMgr = NULL; 
MockTerminalPlatform* g_mockTerminal = NULL; 
CXTestServiceFactory* g_factory = NULL;      
CXAppService*         g_app = NULL;          
CXConfig*             g_config = NULL;       
ICXContext*           g_ctx = NULL;          
CXSignalRepository*   g_repo = NULL;         

CArrayObj*            g_traces = NULL;       
int                   g_currentTick = 0;
int                   g_maxTick = 0;

//--- Helper functions for state names mapping
int SessionStateNameToEnum(string name) {
    name = StringTrimLeft(name); StringTrimRight(name);
    if(name == "SESSION_READY" || name == "ORD_READY") return 0;
    if(name == "SESSION_EXECUTING" || name == "ORD_EXECUTING") return 2;
    if(name == "SESSION_TRAILING_ENTRY" || name == "ORD_TRACKING") return 5;
    if(name == "SESSION_ACTIVE" || name == "POS_MONITORING") return 10;
    if(name == "SESSION_CLOSED" || name == "SYS_CLOSED") return 30;
    if(name == "SESSION_ERROR" || name == "SYS_ERROR") return 99;
    return -1;
}

string SessionStateEnumToName(int state) {
    switch(state) {
        case 0:  return "ORD_READY";
        case 5:  return "ORD_TRACKING";
        case 10: return "POS_MONITORING";
        case 30: return "SYS_CLOSED";
        case 99: return "SYS_ERROR";
        default: return "UNKNOWN_" + IntegerToString(state);
    }
}

string XeStatusEnumToName(int status) {
    switch(status) {
        case 0:  return "XE_READY";
        case 5:  return "XE_PENDING_PLACED";
        case 10: return "XE_EXECUTED";
        case 20: return "XE_CLOSED_SIGNAL";
        case 99: return "XE_ERROR";
        default: return "UNKNOWN_" + IntegerToString(status);
    }
}

//--- Trace Log Entry class definition
class CXTclTraceEntry : public CObject {
public:
    int    tick;
    string expState;
    int    actState;
    string expXe;
    int    actXe;
    bool   isPass;
    string failMsg;

    CXTclTraceEntry() : tick(0), expState(""), actState(-1), expXe(""), actXe(-1), isPass(false), failMsg("") {}
};

int OnInit() {
    g_scenario = CXTclParser::Parse(InpScenarioFile);
    if(IS_INVALID(g_scenario)) return INIT_FAILED;

    g_traces = new CArrayObj();
    CXDatabase* db = new CXDatabase();
    if(db.Open(InpDatabaseName, InpUseCommonPath)) {
        g_repo = new CXSignalRepository(db);
        // [v19.42 Isolation] Clear entire table before starting scenario
        g_repo.TruncateSignals(); 
    }

    g_pricer = new CXVirtualPricer("EURUSD", 0.00001);
    g_pricer.InitModel(g_scenario.m_pricerModel, 1.1000, 2);

    g_mockPriceMgr = new MockPriceManager(NULL);
    g_mockPriceMgr.SetPricer(g_pricer);
    g_mockTerminal = new MockTerminalPlatform();
    g_factory = new CXTestServiceFactory(g_mockPriceMgr, g_mockTerminal);
    
    g_config = new CXConfig("1001", 0.5, "127.0.0.1", false, false, "*", LOG_LVL_TRACE, true, false, true, true, false, true, true, false, false, true, InpDatabaseName, InpUseCommonPath);
    g_app = new CXAppService();
    if(!g_app.Initialize(g_config, g_factory)) return INIT_FAILED;

    g_ctx = g_app.GetContext(); // [v19.55] Get context from initialized app
    g_maxTick = g_scenario.GetMaxTick();
    EventSetMillisecondTimer(100);
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    EventKillTimer();
    SAFE_DELETE(g_repo);
    SAFE_DELETE(g_app);
    SAFE_DELETE(g_config);
    SAFE_DELETE(g_factory);
    SAFE_DELETE(g_pricer);
    SAFE_DELETE(g_scenario);
    SAFE_DELETE(g_traces);
}

/**
 * @brief [v19.45] 핵심 시나리오 구동 및 검증 루프
 */
void ExecuteTick(int tick) {
    CXTclStep* step = g_scenario.GetStep(tick);
    
    // --- 1. [Action Dispatcher] TCL 액션 주입 ---
    if(IS_VALID(step)) {
        for(int i = 0; i < step.m_actions.Total(); i++) {
            CXTclAction* action = (CXTclAction*)step.m_actions.At(i);
            
            // A. MARKET 액션: 가상 호가 변동
            if(action.m_type == "MARKET") {
                double price = action.GetParamDouble("price");
                if(price > 0) g_pricer.OverridePrice(price);
            }
            // B. INJECT: signals 액션: DB 신호 강제 주입
            else if(action.m_type == "INJECT" && action.m_target == "signals") {
                CXSignal* sig = new CXSignal();
                sig.SetCno((int)action.GetParamDouble("cno"));
                sig.SetSno((int)action.GetParamDouble("sno"));
                sig.SetSymbol(g_scenario.GetDefine("SYMBOL"));
                sig.SetDir((int)action.GetParamDouble("dir"));
                sig.SetType((int)action.GetParamDouble("type"));
                sig.SetPriceSignal(action.GetParamDouble("price_signal"));
                sig.SetXAEntry((int)action.GetParamDouble("xa_entry"));
                sig.SetXAExit((int)action.GetParamDouble("xa_exit"));
                sig.SetTEStart(action.GetParamDouble("te_start"));
                sig.SetTEStep(action.GetParamDouble("te_step"));
                sig.SetTELimit(action.GetParamDouble("te_limit"));
                
                string sid = StringFormat("%04d-26052704-%02d-%02d-0-0", sig.GetCno(), sig.GetSno(), (int)action.GetParamDouble("gno"));
                sig.SetSid(sid);
                sig.SetStatus(XE_READY);
                
                g_repo.SaveSignal(sig);
                delete sig;
            }
            // C. INJECT: terminal 액션: 가상 터미널 자산 주입
            else if(action.m_type == "INJECT" && action.m_target == "terminal") {
                bool fill = (action.GetParamDouble("order_fill") == 1.0);
                ulong ticket = (ulong)action.GetParamDouble("ticket");
                string sid = g_scenario.GetDefine("CNO") + "-26052704-" + g_scenario.GetDefine("SNO") + "-" + g_scenario.GetDefine("GNO") + "-0-0";
                g_mockTerminal.InjectMockAsset(fill, ticket, sid, g_scenario.GetDefine("SYMBOL"), 1001, 1, 0.1, 1.1000, 0, 0);
            }
        }
    }

    // --- 2. [Execution] 엔진 구동 ---
    g_pricer.GenerateNextPrice();
    g_mockTerminal.UpdateBrokerTriggeredExits(g_scenario.GetDefine("SYMBOL"), g_pricer.GetBid(), g_pricer.GetAsk());
    
    g_app.Pulse();
    
    ICXAssetManager* assetMgr = CX_GET_OBJ(g_ctx, "asset_mgr", ICXAssetManager);
    if(IS_VALID(assetMgr)) assetMgr.Pulse(NULL);

    // --- 3. [Expect Verifier] 기대값 대조 및 판정 ---
    if(IS_VALID(step) && step.m_expectations.Total() > 0) {
        for(int i = 0; i < step.m_expectations.Total(); i++) {
            CXTclExpect* exp = (CXTclExpect*)step.m_expectations.At(i);
            CXTclTraceEntry* trace = new CXTclTraceEntry();
            trace.tick = tick;
            
            bool passed = true;
            if(exp.m_type == "session") {
                string sid = StringFormat("%s-26052704-%s-%s-0-0", g_scenario.GetDefine("CNO"), g_scenario.GetDefine("SNO"), g_scenario.GetDefine("GNO"));
                ICXAssetManager* mgr = CX_GET_OBJ(g_ctx, "asset_mgr", ICXAssetManager);
                ICXTradingSession* session = IS_VALID(mgr) ? mgr.FindSessionBySid(sid) : NULL;
                
                int actState = IS_VALID(session) ? session.GetState() : -1;
                int expState = SessionStateNameToEnum(exp.GetParam("state"));
                
                trace.expState = exp.GetParam("state");
                trace.actState = actState;
                
                if(exp.GetParam("state") != "" && actState != expState) passed = false;
                
                // xe_status 검증
                int actXe = g_repo.GetStatusBySid(sid);
                int expXe = -1;
                string expXeStr = exp.GetParam("xe_status");
                if(expXeStr == "XE_READY") expXe = 0;
                if(expXeStr == "XE_PENDING_PLACED") expXe = 5;
                if(expXeStr == "XE_EXECUTED") expXe = 10;
                if(expXeStr == "XE_CLOSED_SIGNAL") expXe = 20;
                
                trace.expXe = expXeStr;
                trace.actXe = actXe;
                if(expXeStr != "" && actXe != expXe) passed = false;
            }
            
            trace.isPass = passed;
            if(!passed) trace.failMsg = exp.m_failMsg;
            g_traces.Add(trace);
            
            if(!passed) {
                PrintFormat("!!! [TICK %d] FAILED: Exp State:%s, Act State:%s | Exp XE:%s, Act XE:%s", 
                            tick, trace.expState, SessionStateEnumToName(trace.actState), trace.expXe, XeStatusEnumToName(trace.actXe));
            } else {
                PrintFormat("OK [TICK %d]: Expectations matched.", tick);
            }
        }
    }
}

void OnTimer() {
    g_currentTick++;
    if(g_currentTick > g_maxTick) { 
        Print("--- ALL TCL SCENARIO STEPS COMPLETED ---");
        EventKillTimer();
        ExpertRemove(); 
        return; 
    }
    ExecuteTick(g_currentTick);
}
