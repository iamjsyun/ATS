//+------------------------------------------------------------------+
//|                                           CXScenarioRunner.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//| [v1.2] Scenario-based Signal Injector for ATSE Self-Testing      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://github.com/google-gemini/gemini-cli"
#property version   "1.20"
#property strict

#include "Scenarios\CXScenarioLoader.mqh"
#include "..\CXTrade\Infra\CXDatabase.mqh"
#include "..\CXTrade\Infra\CXSignalRepository.mqh"
#include "..\CXTrade\Models\CXSignal.mqh"
#include "..\CXTrade\Interfaces\CXDefine.mqh"
#include "..\CXTrade\Infra\Sync\CXTerminalScanner.mqh"

//--- [Inputs]
input string InpScenarioFile = "ATSE\\scenario_sample.csv"; // CSV Filename (MQL5/Files)
input string InpDatabaseName = "ATS.db";                    // Target Database
input bool   InpUseCommonPath = true;                       // DB Path

//--- Global Variables
CArrayObj*         g_queue = NULL;
CXDatabase*        g_db = NULL;
CXSignalRepository* g_repo = NULL;
CXTerminalScanner* g_scanner = NULL;
datetime           g_nextReleaseTime = 0;
int                g_currentIndex = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    g_queue = new CArrayObj();
    if(CXScenarioLoader::Load(InpScenarioFile, g_queue) <= 0) {
        Print("[RUNNER] ERROR: Scenario file empty or missing.");
        return INIT_FAILED;
    }

    g_db = new CXDatabase();
    if(!g_db.OpenByParams(InpDatabaseName, InpUseCommonPath)) {
        Print("[RUNNER] ERROR: Failed to open database.");
        return INIT_FAILED;
    }

    g_repo = new CXSignalRepository(g_db);
    g_scanner = new CXTerminalScanner();
    
    // 첫 번째 신호의 릴리즈 시간 설정
    if(g_queue.Total() > 0) {
        CXScenarioParam* p = (CXScenarioParam*)g_queue.At(0);
        g_nextReleaseTime = TimeCurrent() + p.release_delay;
    }

    EventSetMillisecondTimer(500);
    Print("[RUNNER] Initialized. Waiting for first release...");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
    if(CheckPointer(g_queue) == POINTER_DYNAMIC) delete g_queue;
    if(CheckPointer(g_repo) == POINTER_DYNAMIC) delete g_repo;
    if(CheckPointer(g_db) == POINTER_DYNAMIC) delete g_db;
    if(CheckPointer(g_scanner) == POINTER_DYNAMIC) delete g_scanner;
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {
    if(g_currentIndex >= g_queue.Total()) {
        PrintSummary();
        ExpertRemove();
        return;
    }

    if(TimeCurrent() >= g_nextReleaseTime) {
        ExecuteScenario(g_currentIndex);
        g_currentIndex++;
        
        if(g_currentIndex < g_queue.Total()) {
            CXScenarioParam* p = (CXScenarioParam*)g_queue.At(g_currentIndex);
            g_nextReleaseTime = TimeCurrent() + p.release_delay;
        }
    }
}

/**
 * @brief [v13.3] 상태 명칭을 ENUM_XE_STATUS로 변환 (No Magic Numbers)
 */
int StatusNameToEnum(string name) {
    if(name == "READY")          return XE_READY;
    if(name == "PENDING_PLACED") return XE_PENDING_PLACED;
    if(name == "EXECUTED")       return XE_EXECUTED;
    if(name == "CLOSED_SIGNAL")  return XE_CLOSED_SIGNAL;
    if(name == "CLOSED_SL")      return XE_CLOSED_SL;
    if(name == "CLOSED_TP")      return XE_CLOSED_TP;
    if(name == "CLOSED_MANUAL")  return XE_CLOSED_MANUAL;
    if(name == "ERROR")          return XE_ERROR;
    return -1;
}

/**
 * @brief 전체 테스트 결과 요약 출력
 */
void PrintSummary() {
    Print("==================================================");
    Print("ATSE Self-Test Execution Summary");
    Print("==================================================");
    
    int passed = 0, failed = 0, skipped = 0;

    for(int i = 0; i < g_queue.Total(); i++) {
        CXScenarioParam* p = (CXScenarioParam*)g_queue.At(i);
        int expected = StatusNameToEnum(p.exp_status);

        if(p.action == "ARCHIVE" || expected < 0) {
            PrintFormat("[%02d] SKIP: %s (%s)", i, p.comment, p.action);
            skipped++;
            continue;
        }

        int actual = g_repo.GetStatusBySid(p.sid_used);
        string result = (actual == expected) ? "PASS" : "FAIL";
        
        if(actual == expected) passed++; else failed++;

        PrintFormat("[%02d] %-4s | SID:%-20s | Exp:%-12s | Act:%-2d | %s", 
                    i, result, p.sid_used, p.exp_status, actual, p.comment);
    }

    Print("==================================================");
    PrintFormat("TOTAL: %d | PASS: %d | FAIL: %d | SKIP: %d", 
                g_queue.Total(), passed, failed, skipped);
    Print("==================================================");
}

//+------------------------------------------------------------------+
//| 시나리오 실행 로직                                                 |
//+------------------------------------------------------------------+
void ExecuteScenario(int index) {
    CXScenarioParam* p = (CXScenarioParam*)g_queue.At(index);
    if(CheckPointer(p) == POINTER_INVALID) return;

    PrintFormat("[RUNNER-EXEC] [%d/%d] Action: %s | Comment: %s", 
                index+1, g_queue.Total(), p.action, p.comment);

    if(p.action == "INSERT") {
        if(p.sid != "") {
            ICXSignal* existingDB = g_repo.GetSignalBySid(p.sid);
            if(CheckPointer(existingDB) != POINTER_INVALID) {
                PrintFormat("[RUNNER-SKIP] SID:%s already exists in Database.", p.sid);
                p.sid_used = p.sid;
                delete existingDB;
                return;
            }
        }

        if(p.sid != "" && g_scanner.IsSidExists(p.sid)) {
            PrintFormat("[RUNNER-SKIP] SID:%s already exists in Terminal.", p.sid);
            p.sid_used = p.sid;
            return;
        }

        CXSignal* sig = CreateSignalFromParam(p);
        if(CheckPointer(sig) != POINTER_INVALID) {
            p.sid_used = sig.GetSid(); 
            if(g_repo.Add(sig)) {
                PrintFormat("[RUNNER] SUCCESS: Signal Injected. SID:%s", sig.GetSid());
            } else {
                Print("[RUNNER] ERROR: Failed to add signal to DB.");
            }
            delete sig;
        }
    }
    else if(p.action == "EXIT") {
        CXSignal* sig = g_repo.GetSignalByCnoSno(p.cno, p.sno, p.symbol);
        if(CheckPointer(sig) != POINTER_INVALID) {
            p.sid_used = sig.GetSid(); 
            sig.xa_exit = XA_ACTIVE;
            if(g_repo.UpdateStatus(sig)) {
                PrintFormat("[RUNNER] SUCCESS: Exit Intent Injected for SID:%s", sig.GetSid());
            }
            delete sig;
        } else {
            PrintFormat("[RUNNER] WARN: No active signal found for CNO:%d SNO:%d Sym:%s", p.cno, p.sno, p.symbol);
        }
    }
    else if(p.action == "ARCHIVE") {
        g_repo.DeleteSignalByCnoSno(p.cno, p.sno, p.symbol);
    }
}

//+------------------------------------------------------------------+
//| Param을 CXSignal 객체로 변환 (SSOC 정책 반영)                      |
//+------------------------------------------------------------------+
CXSignal* CreateSignalFromParam(CXScenarioParam* p) {
    CXSignal* sig = new CXSignal();
    
    sig.cno = p.cno;
    sig.magic = sig.cno; 
    sig.sno = p.sno;
    sig.symbol = p.symbol;
    sig.dir = (ENUM_CX_DIRECTION)p.dir;
    sig.type = (ENUM_CX_ORDER_TYPE)p.type;
    sig.lot = p.lot;
    
    MqlTick lastTick;
    if(SymbolInfoTick(sig.symbol, lastTick)) {
        sig.price_signal = (sig.dir == CX_DIR_BUY) ? lastTick.ask : lastTick.bid;
    } else {
        sig.price_signal = 0; 
    }

    sig.sl = p.sl_pts;
    sig.tp = p.tp_pts;
    sig.te_start = p.te_pts;
    sig.ts_start = p.ts_pts;
    
    sig.xa_entry = XA_ACTIVE; 
    sig.xa_exit = 0;
    sig.xe_status = XE_READY;

    if(p.sid != "") {
        sig.SetSid(p.sid);
    } else {
        string autoSid = StringFormat("%d-%d-%d-%d-%I64u", sig.cno, sig.sno, sig.dir, sig.type, TimeCurrent());
        sig.SetSid(autoSid);
    }

    return sig;
}
