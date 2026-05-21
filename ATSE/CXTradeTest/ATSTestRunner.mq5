//+------------------------------------------------------------------+
//|                                              ATSTestRunner.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//|                    Task-Level Unit Test Runner EA for ATSE       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://github.com/google-gemini/gemini-cli"
#property version   "1.00"
#property strict

#include "Scenarios\TestEntryValidate.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("==================================================");
    Print("Starting ATSE Unit Tests (Task-Level Isolation)...");
    Print("==================================================");
    
    int passed = 0;
    int failed = 0;
    
    // Run Scenarios
    if (TestEntryValidate::Run()) passed++; else failed++;
    
    // Add more test classes here...
    
    Print("==================================================");
    PrintFormat("Test Run Complete. Suites Passed: %d, Suites Failed: %d", passed, failed);
    Print("==================================================");
    
    // 테스트 완료 후 EA 자동 종료 (불필요한 리소스 점유 방지)
    ExpertRemove();
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("ATSE Unit Tests EA Unloaded.");
}

//+------------------------------------------------------------------+
//| Expert tick function (Not used in Test Runner)                   |
//+------------------------------------------------------------------+
void OnTick() {}
