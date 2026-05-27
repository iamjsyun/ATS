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
#include "..\CXTrade\Platform\Core\Interfaces\ICXAssetManager.mqh"

//--- [Inputs]
input string InpScenarioFile  = "ATSE\\test_golden_path.tcl"; // TCL Filename (MQL5/Files)
input string InpDatabaseName  = "ATS.db";                     // Target Database
input bool   InpUseCommonPath = true;                        // DB Path

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
    name = StringTrimLeft(StringTrimRight(name));
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
        g_repo.DeleteSignalByCnoSno((int)StringToInteger(g_scenario.GetDefine("CNO")), (int)StringToInteger(g_scenario.GetDefine("SNO")), g_scenario.GetDefine("SYMBOL"));
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

    g_ctx = g_factory.m_ctx;
    g_maxTick = 100; // Simplified for E2E
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

void ExecuteTick(int tick) {
    g_app.Pulse();
    
    ICXAssetManager* assetMgr = CX_GET_OBJ(g_ctx, "asset_mgr", ICXAssetManager);
    if(IS_VALID(assetMgr)) assetMgr.Pulse(NULL);
}

void OnTimer() {
    g_currentTick++;
    if(g_currentTick > g_maxTick) { ExpertRemove(); return; }
    ExecuteTick(g_currentTick);
}
