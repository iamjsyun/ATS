//+------------------------------------------------------------------+
//|                                           CXScenarioRunner.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//| [v1.0] TCL-based Deterministic E2E Test Runner for ATSE          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://github.com/google-gemini/gemini-cli"
#property version   "2.00"
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

//--- [Inputs]
input string InpScenarioFile  = "ATSE\\test_golden_path.tcl"; // TCL Filename (MQL5/Files)
input string InpDatabaseName  = "ATS.db";                     // Target Database
input bool   InpUseCommonPath = true;                        // DB Path

//--- Global Instances
CXTclScenario*        g_scenario = NULL;
CXVirtualPricer*      g_pricer = NULL;
MockPriceManager*     g_mockPriceMgr = NULL; // AppService will delete this
MockTerminalPlatform* g_mockTerminal = NULL; // AppService will delete this
CXTestServiceFactory* g_factory = NULL;      // Owned by EA
CXAppService*         g_app = NULL;          // Owned by EA
CXConfig*             g_config = NULL;       // Owned by EA
ICXContext*           g_ctx = NULL;          // Owned by EA (retrieved via factory)
CXSignalRepository*   g_repo = NULL;         // Temporary repository for query/cleanup

CArrayObj*            g_traces = NULL;       // Trace history for report
int                   g_currentTick = 0;
int                   g_maxTick = 0;

//--- Helper functions for state names mapping
int SessionStateNameToEnum(string name) {
    name = StringTrimLeft(StringTrimRight(name));
    if(name == "SESSION_READY" || name == "ORD_READY") return 0;
    if(name == "SESSION_VALIDATING" || name == "ORD_VALIDATING") return 1;
    if(name == "SESSION_EXECUTING" || name == "ORD_EXECUTING") return 2;
    if(name == "SESSION_PENDING" || name == "ORD_PENDING") return 3;
    if(name == "SESSION_TRAILING_ENTRY" || name == "ORD_TRAILING") return 5;
    if(name == "SESSION_ACTIVE" || name == "POS_ACTIVE") return 10;
    if(name == "SESSION_TRAILING_STOP" || name == "POS_TRAILING") return 15;
    if(name == "SESSION_LIQUIDATING" || name == "POS_LIQUIDATING") return 20;
    if(name == "SESSION_CLOSED" || name == "SYS_CLOSED") return 30;
    if(name == "SESSION_ERROR" || name == "SYS_ERROR") return 99;
    return -1;
}

int XeStatusNameToEnum(string name) {
    name = StringTrimLeft(StringTrimRight(name));
    if(name == "XE_READY" || name == "READY") return 0;
    if(name == "XE_PENDING_PLACED" || name == "PENDING_PLACED") return 5;
    if(name == "XE_EXECUTED" || name == "EXECUTED") return 10;
    if(name == "XE_QUARANTINED" || name == "QUARANTINED") return 15;
    if(name == "XE_CLOSED_SIGNAL" || name == "CLOSED_SIGNAL") return 20;
    if(name == "XE_CLOSED_SL" || name == "CLOSED_SL") return 21;
    if(name == "XE_CLOSED_TP" || name == "CLOSED_TP") return 22;
    if(name == "XE_CLOSED_MANUAL" || name == "CLOSED_MANUAL") return 24;
    if(name == "XE_ERROR" || name == "ERROR") return 99;
    
    // Fallback: direct integer string
    long val = StringToInteger(name);
    if(val > 0 || name == "0") return (int)val;
    return -1;
}

string SessionStateEnumToName(int state) {
    switch(state) {
        case 0:  return "ORD_READY";
        case 1:  return "ORD_VALIDATING";
        case 2:  return "ORD_EXECUTING";
        case 3:  return "ORD_PENDING";
        case 5:  return "ORD_TRAILING";
        case 10: return "POS_ACTIVE";
        case 15: return "POS_TRAILING";
        case 20: return "POS_LIQUIDATING";
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
        case 15: return "XE_QUARANTINED";
        case 20: return "XE_CLOSED_SIGNAL";
        case 21: return "XE_CLOSED_SL";
        case 22: return "XE_CLOSED_TP";
        case 24: return "XE_CLOSED_MANUAL";
        case 25: return "XE_VERIFY_ABS";
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
    virtual ~CXTclTraceEntry() override {}
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("[RUNNER-INIT] Starting TCL scenario runner bootstrap...");

    // 1. Parse TCL Scenario file
    g_scenario = CXTclParser::Parse(InpScenarioFile);
    if(CheckPointer(g_scenario) == POINTER_INVALID) {
        Print("[RUNNER-INIT] ERROR: Failed to parse scenario file.");
        return INIT_FAILED;
    }

    g_traces = new CArrayObj();

    // 2. Pre-clean test database channel signals
    CXDatabase* db = new CXDatabase();
    if(db.Open(InpDatabaseName, InpUseCommonPath)) {
        g_repo = new CXSignalRepository(db);
        
        int testCno = (int)StringToInteger(g_scenario.GetDefine("CNO"));
        int testSno = (int)StringToInteger(g_scenario.GetDefine("SNO"));
        string testSym = g_scenario.GetDefine("SYMBOL");
        if(testSym == "") testSym = "EURUSD";

        // Clean targeted channels
        g_repo.DeleteSignalByCnoSno(testCno, testSno, testSym);
        
        // Clean zombie/recovery channel elements
        g_repo.DeleteSignalByCnoSno(1002, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1003, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1004, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1005, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1006, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1007, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1008, 1, "EURUSD");
        g_repo.DeleteSignalByCnoSno(1009, 1, "EURUSD");

        Print("[RUNNER-INIT] Cleaned up previous scenario records.");
    } else {
        Print("[RUNNER-INIT] ERROR: Failed to open DB to clean signals.");
        delete db;
        return INIT_FAILED;
    }

    // 3. Initialize Pricer
    string pricerSym = g_scenario.m_pricerSymbol;
    if(pricerSym == "") pricerSym = "EURUSD";
    double pointVal = SymbolInfoDouble(pricerSym, SYMBOL_POINT);
    if(pointVal <= 0) pointVal = 0.00001;

    g_pricer = new CXVirtualPricer(pricerSym, pointVal);
    
    double startPrice = g_pricer.GetCurrentPrice();
    string startPriceStr = g_scenario.GetPricerParam("start");
    if(startPriceStr == "") startPriceStr = g_scenario.GetPricerParam("price");
    if(startPriceStr != "") startPrice = StringToDouble(startPriceStr);

    int spreadPts = (int)StringToInteger(g_scenario.GetPricerParam("spread"));
    if(spreadPts <= 0) spreadPts = 2;

    g_pricer.InitModel(g_scenario.m_pricerModel, startPrice, spreadPts);

    if(g_scenario.m_pricerModel == "GBM") {
        double drift = StringToDouble(g_scenario.GetPricerParam("drift"));
        double vol = StringToDouble(g_scenario.GetPricerParam("volatility"));
        g_pricer.SetGBM(drift, vol);
    }
    else if(g_scenario.m_pricerModel == "OU") {
        double theta = StringToDouble(g_scenario.GetPricerParam("theta"));
        double meanPrice = StringToDouble(g_scenario.GetPricerParam("mean_price"));
        double vol = StringToDouble(g_scenario.GetPricerParam("volatility"));
        g_pricer.SetOU(theta, meanPrice, vol);
    }
    else if(g_scenario.m_pricerModel == "TREND_SPIKE" || g_scenario.m_pricerModel == "TREND") {
        double slope = StringToDouble(g_scenario.GetPricerParam("trend_slope"));
        double jumpP = StringToDouble(g_scenario.GetPricerParam("jump_prob"));
        double jumpM = StringToDouble(g_scenario.GetPricerParam("jump_mean"));
        double jumpS = StringToDouble(g_scenario.GetPricerParam("jump_std"));
        g_pricer.SetTrendSpike(slope, jumpP, jumpM, jumpS);
    }

    // 4. Create Mock components (owned and deleted by AppService)
    g_mockPriceMgr = new MockPriceManager(NULL);
    g_mockPriceMgr.SetPricer(g_pricer);
    g_mockTerminal = new MockTerminalPlatform();

    // 5. Initialize AppService with custom DI Factory
    g_factory = new CXTestServiceFactory(g_mockPriceMgr, g_mockTerminal);
    
    // Create config covering test magics
    g_config = new CXConfig("1001,1002,1003,1004,1005,1006,1007,1008,1009", 0.5, "127.0.0.1:878", 
                            false, false, "*", LOG_LVL_TRACE,
                            true, false, true,
                            true, false, true,
                            true, false, false, true,
                            InpDatabaseName, InpUseCommonPath);

    g_app = new CXAppService();
    if(!g_app.Initialize(g_config, g_factory)) {
        Print("[RUNNER-INIT] ERROR: App Service bootstrap failed.");
        return INIT_FAILED;
    }

    // Capture global context
    g_ctx = g_factory.m_ctx;

    // Determine max ticks
    g_maxTick = 0;
    for(int i = 0; i < g_scenario.m_steps.Total(); i++) {
        CXTclStep* step = (CXTclStep*)g_scenario.m_steps.At(i);
        if(step.m_tickNum > g_maxTick) {
            g_maxTick = step.m_tickNum;
        }
    }

    PrintFormat("[RUNNER-INIT] Bootstrap completed. Max tick determined: %d. Starting Virtual Clock.", g_maxTick);
    
    // Set fast timer (100ms interval for simulated E2E runs)
    EventSetMillisecondTimer(100);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();

    // Clean up temporary repo and db
    if(CheckPointer(g_repo) == POINTER_DYNAMIC) delete g_repo;

    // Delete dynamic resources owned by EA
    if(CheckPointer(g_app) == POINTER_DYNAMIC) delete g_app; // deletes mockPriceMgr and mockTerminal
    if(CheckPointer(g_config) == POINTER_DYNAMIC) delete g_config;
    if(CheckPointer(g_factory) == POINTER_DYNAMIC) delete g_factory;
    if(CheckPointer(g_pricer) == POINTER_DYNAMIC) delete g_pricer;
    if(CheckPointer(g_scenario) == POINTER_DYNAMIC) delete g_scenario;
    if(CheckPointer(g_traces) == POINTER_DYNAMIC) delete g_traces;

    Print("[RUNNER] Deinitialized.");
}

//+------------------------------------------------------------------+
//| Action execution logic                                           |
//+------------------------------------------------------------------+
void ProcessAction(CXTclAction* act) {
    PrintFormat("[RUNNER-ACTION] > %s : %s", act.m_type, act.m_target);

    if(act.m_type == "MARKET") {
        if(act.GetParam("price") != "") {
            double p = act.GetParamDouble("price");
            g_pricer.OverridePrice(p);
        } else {
            int tc = act.GetParamInt("tick_count", 1);
            for(int c = 0; c < tc; c++) {
                g_pricer.GenerateNextPrice();
            }
        }
        g_mockTerminal.UpdateBrokerTriggeredExits(act.m_target, g_pricer.GetBid(), g_pricer.GetAsk());
        PrintFormat("[RUNNER-MKT] Symbol: %s | Price: %.5f | Bid: %.5f | Ask: %.5f", act.m_target, g_pricer.GetCurrentPrice(), g_pricer.GetBid(), g_pricer.GetAsk());
    }
    else if(act.m_type == "INJECT") {
        if(act.m_target == "signals") {
            int xaExit = act.GetParamInt("xa_exit", 0);
            
            string symbol = act.GetParam("symbol");
            if(symbol == "") symbol = g_scenario.GetDefine("SYMBOL");
            if(symbol == "") symbol = "EURUSD";

            int cno = act.GetParamInt("cno", (int)StringToInteger(g_scenario.GetDefine("CNO")));
            int sno = act.GetParamInt("sno", (int)StringToInteger(g_scenario.GetDefine("SNO")));
            int dir = act.GetParamInt("dir", (int)StringToInteger(g_scenario.GetDefine("DIR")));
            int type = act.GetParamInt("type", (int)StringToInteger(g_scenario.GetDefine("TYPE")));
            
            // Check if this is an exit intent injection for an existing signal
            if(xaExit == 1) {
                CXSignal* sig = g_repo.GetSignalByCnoSno(cno, sno, symbol);
                if(CheckPointer(sig) != POINTER_INVALID) {
                    sig.xa_exit = XA_ACTIVE; // 1
                    g_repo.UpdateStatus(sig);
                    PrintFormat("[RUNNER-INJECT] Signal Exit Intent updated for SID:%s", sig.GetSid());
                    delete sig;
                    return;
                }
            }

            // Create new signal entry
            CXSignal* sig = new CXSignal();
            sig.cno = cno;
            sig.sno = sno;
            sig.symbol = symbol;
            sig.dir = (ENUM_CX_DIRECTION)dir;
            sig.type = (ENUM_CX_ORDER_TYPE)type;
            sig.lot = act.GetParamDouble("lot", StringToDouble(g_scenario.GetDefine("LOT")));
            if(sig.lot <= 0) sig.lot = 0.1;

            sig.magic = sig.cno;
            sig.price_signal = act.GetParamDouble("price_signal", g_pricer.GetCurrentPrice());
            sig.sl = act.GetParamDouble("sl", 0.0);
            sig.tp = act.GetParamDouble("tp", 0.0);

            sig.te_start = act.GetParamDouble("te_start", 0.0);
            sig.te_step = act.GetParamDouble("te_step", 0.0);
            sig.te_limit = act.GetParamDouble("te_limit", 0.0);

            sig.ts_start = act.GetParamDouble("ts_start", 0.0);
            sig.ts_step = act.GetParamDouble("ts_step", 0.0);

            sig.xa_entry = act.GetParamInt("xa_entry", XA_ACTIVE);
            sig.xa_exit = xaExit;
            sig.xe_status = XE_READY;

            string actSid = act.GetParam("sid");
            if(actSid == "") {
                string dateStr = act.GetParam("yymmddhh");
                if(dateStr == "") dateStr = "26052704";
                int gno = act.GetParamInt("gno", 1);
                actSid = StringFormat("%04d-%s-%02d-%02d-%d-%d", sig.cno, dateStr, sig.sno, gno, sig.dir, sig.type);
            }
            sig.SetSid(actSid);

            if(g_repo.Add(sig)) {
                PrintFormat("[RUNNER-INJECT] Signal added to DB. SID:%s, Price:%.5f, SL:%.0f, TP:%.0f", sig.GetSid(), sig.price_signal, sig.sl, sig.tp);
            } else {
                PrintFormat("[RUNNER-WARN] Duplicate or Fail adding signal to DB. SID:%s", sig.GetSid());
            }
            delete sig;
        }
        else if(act.m_target == "terminal") {
            bool orderFill = act.GetParamBool("order_fill");
            ulong ticket = (ulong)act.GetParamInt("ticket");

            string symbol = g_scenario.GetDefine("SYMBOL");
            if(symbol == "") symbol = "EURUSD";
            int cno = (int)StringToInteger(g_scenario.GetDefine("CNO"));
            int sno = (int)StringToInteger(g_scenario.GetDefine("SNO"));
            int dir = (int)StringToInteger(g_scenario.GetDefine("DIR"));
            double lot = StringToDouble(g_scenario.GetDefine("LOT"));
            if(lot <= 0) lot = 0.1;
            double price = g_pricer.GetCurrentPrice();
            double sl = 0, tp = 0;

            CXSignal* sig = g_repo.GetSignalByCnoSno(cno, sno, symbol);
            string sid = "";
            if(CheckPointer(sig) != POINTER_INVALID) {
                sid = sig.GetSid();
                dir = sig.dir;
                lot = sig.lot;
                price = sig.price_signal;
                sl = price - sig.sl * SymbolInfoDouble(symbol, SYMBOL_POINT);
                tp = price + sig.tp * SymbolInfoDouble(symbol, SYMBOL_POINT);
                delete sig;
            } else {
                sid = StringFormat("%04d-26052704-%02d-01-%d-0", cno, sno, dir);
            }

            g_mockTerminal.InjectMockAsset(orderFill, ticket, sid, symbol, cno, dir, lot, price, sl, tp);
        }
    }
}

//+------------------------------------------------------------------+
//| Expectation verification logic                                   |
//+------------------------------------------------------------------+
void VerifyExpectation(int tick, CXTclExpect* exp) {
    string symbol = g_scenario.GetDefine("SYMBOL");
    if(symbol == "") symbol = "EURUSD";
    int cno = (int)StringToInteger(g_scenario.GetDefine("CNO"));
    int sno = (int)StringToInteger(g_scenario.GetDefine("SNO"));

    CXSignal* sig = g_repo.GetSignalByCnoSno(cno, sno, symbol);
    string sid = "";
    int actualXeStatus = -1;
    if(CheckPointer(sig) != POINTER_INVALID) {
        sid = sig.GetSid();
        actualXeStatus = sig.xe_status;
        delete sig;
    }

    if(sid == "") {
        int dir = (int)StringToInteger(g_scenario.GetDefine("DIR"));
        sid = StringFormat("%04d-26052704-%02d-01-%d-0", cno, sno, dir);
    }

    ICXSessionManager* sessionMgr = CX_GET_OBJ(g_ctx, "session_mgr", ICXSessionManager);
    ICXTradingSession* session = (CheckPointer(sessionMgr) != POINTER_INVALID) ? sessionMgr.FindSessionBySid(sid) : NULL;

    int actualState = (CheckPointer(session) != POINTER_INVALID) ? session.GetState() : 30; // SYS_CLOSED

    // Verify session sequence state
    string expStateName = exp.GetParam("state");
    bool stateMatch = true;
    int expectedStateVal = -1;
    if(expStateName != "") {
        expectedStateVal = SessionStateNameToEnum(expStateName);
        if(actualState != expectedStateVal) {
            stateMatch = false;
        }
    }

    // Verify xe_status
    string expXeStatusName = exp.GetParam("xe_status");
    bool xeMatch = true;
    int expectedXeVal = -1;
    if(expXeStatusName != "") {
        expectedXeVal = XeStatusNameToEnum(expXeStatusName);
        if(actualXeStatus != expectedXeVal) {
            xeMatch = false;
        }
    }

    bool isPass = stateMatch && xeMatch;

    // Track trace logs
    CXTclTraceEntry* tr = new CXTclTraceEntry();
    tr.tick = tick;
    tr.expState = expStateName;
    tr.actState = actualState;
    tr.expXe = expXeStatusName;
    tr.actXe = actualXeStatus;
    tr.isPass = isPass;
    tr.failMsg = exp.m_failMsg;
    g_traces.Add(tr);

    string resultStr = isPass ? "PASS" : "FAIL";
    PrintFormat("[RUNNER-EXPECT] %s | Tick:%d | State: Exp:%s Act:%s | XeStatus: Exp:%s Act:%s %s", 
                resultStr, tick, 
                (expStateName != "") ? expStateName : "ANY", SessionStateEnumToName(actualState),
                (expXeStatusName != "") ? expXeStatusName : "ANY", XeStatusEnumToName(actualXeStatus),
                (!isPass && exp.m_failMsg != "") ? "| Msg: " + exp.m_failMsg : "");
}

//+------------------------------------------------------------------+
//| Execute actions, engine pulses, and assertions for current tick  |
//+------------------------------------------------------------------+
void ExecuteTick(int tick) {
    CXTclStep* step = NULL;
    for(int i = 0; i < g_scenario.m_steps.Total(); i++) {
        CXTclStep* s = (CXTclStep*)g_scenario.m_steps.At(i);
        if(s.m_tickNum == tick) {
            step = s;
            break;
        }
    }

    PrintFormat("[RUNNER-TICK] --- Virtual Tick: %d ---", tick);

    // 1. Process Actions (Market update, injections)
    if(step != NULL) {
        for(int i = 0; i < step.m_actions.Total(); i++) {
            CXTclAction* act = (CXTclAction*)step.m_actions.At(i);
            ProcessAction(act);
        }
    }

    // 2. Pulse Reverse Injector (Orphan Asset Recovery)
    CXReverseInjector* injector = CX_GET_OBJ(g_ctx, "injector", CXReverseInjector);
    if(CheckPointer(injector) != POINTER_INVALID) {
        CXParam xp;
        injector.Pulse(GetPointer(xp));
    }

    // 3. Pulse ATSE Engine (Propagate state changes)
    for(int p = 0; p < 5; p++) {
        g_app.Pulse();
    }

    // 4. Verify Expectations
    if(step != NULL) {
        for(int i = 0; i < step.m_expectations.Total(); i++) {
            CXTclExpect* exp = (CXTclExpect*)step.m_expectations.At(i);
            VerifyExpectation(tick, exp);
        }
    }
}

//+------------------------------------------------------------------+
//| Export execution traces as structured JSON log                   |
//+------------------------------------------------------------------+
void ExportJsonTrace() {
    string filename = "_log\\SCEN_" + g_scenario.m_id + "_trace.json";
    int handle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_ANSI);
    if(handle == INVALID_HANDLE) {
        PrintFormat("[RUNNER-JSON] ERROR: Failed to open %s for writing.", filename);
        return;
    }

    string json = "{\n";
    json += "  \"scenario_id\": \"" + g_scenario.m_id + "\",\n";
    json += "  \"description\": \"" + g_scenario.m_desc + "\",\n";
    json += "  \"pipeline_traces\": [\n";

    for(int i = 0; i < g_traces.Total(); i++) {
        CXTclTraceEntry* tr = (CXTclTraceEntry*)g_traces.At(i);
        json += "    {\n";
        json += StringFormat("      \"virtual_tick\": %d,\n", tr.tick);
        json += "      \"expected_state\": \"" + tr.expState + "\",\n";
        json += "      \"actual_state\": \"" + SessionStateEnumToName(tr.actState) + "\",\n";
        json += "      \"expected_xe_status\": \"" + tr.expXe + "\",\n";
        json += "      \"actual_xe_status\": \"" + XeStatusEnumToName(tr.actXe) + "\",\n";
        json += "      \"verification\": \"" + (tr.isPass ? "PASS" : "FAIL") + "\",\n";
        json += "      \"fail_msg\": \"" + tr.failMsg + "\"\n";
        json += "    }";
        if(i < g_traces.Total() - 1) json += ",";
        json += "\n";
    }

    json += "  ]\n";
    json += "}\n";

    FileWriteString(handle, json);
    FileClose(handle);
    PrintFormat("[RUNNER-JSON] SUCCESS: Exported trace log to %s", filename);
}

//+------------------------------------------------------------------+
//| Print E2E execution report summary                               |
//+------------------------------------------------------------------+
void PrintSummary() {
    Print("==================================================");
    Print("ATSE TCL Self-Test Execution Summary");
    Print("==================================================");
    PrintFormat("Scenario ID: %s", g_scenario.m_id);
    PrintFormat("Description: %s", g_scenario.m_desc);
    Print("--------------------------------------------------");

    int total = g_traces.Total();
    int passed = 0;
    int failed = 0;

    for(int i = 0; i < total; i++) {
        CXTclTraceEntry* tr = (CXTclTraceEntry*)g_traces.At(i);
        if(tr.isPass) passed++;
        else failed++;
    }

    PrintFormat("VERDICT: %s", (failed == 0) ? "PASS" : "FAIL");
    PrintFormat("TOTAL ASSERTIONS: %d | PASSED: %d | FAILED: %d", total, passed, failed);
    Print("==================================================");

    // Export trace to JSON
    ExportJsonTrace();
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {
    g_currentTick++;
    if(g_currentTick > g_maxTick + 2) {
        PrintSummary();
        ExpertRemove();
        return;
    }

    ExecuteTick(g_currentTick);
}
