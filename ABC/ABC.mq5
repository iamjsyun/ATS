//+------------------------------------------------------------------+
//|                                                          ABC.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//| [v1.5] MeetAlgo Indicator Monitor - Dynamic Symbol Version        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://github.com/google-gemini/gemini-cli"
#property version   "1.50"
#property strict

//--- CONFIGURATIONS ---
input group             "--- Target Settings ---"
input string            InpTargetSymbol         = "";        // Target Symbol (Empty = Current Chart)
input ENUM_TIMEFRAMES   InpTargetPeriod         = PERIOD_CURRENT; // Target Period

input group             "--- Connection Settings ---"
input string            InpIndicatorPath        = "MeetAlgo_ChannelTrading_MT5"; // Filename (Root or Market)

input group             "--- Indicator Parameters ---"
input double            InpDeviations           = 2.0;      // Deviations
input int               InpMinimumBarRedraw     = 100;      // Minimum Bar Redraw
input bool              InpShowAnalysisReport   = true;     // Show Analysis Report
input bool              InpShowProfitValue      = true;     // Show Profit Value
input color             InpAnalysisColor        = clrPurple;// AnalysisColor
input color             InpAnalysisLabel        = clrLimeGreen; // AnalysisLabel
input bool              InpIndicatorRunFromICustom = true;  // Indicator Run From iCustom

input group             "--- Registration ---"
input string            InpSerialKey            = "IKJKGFFFFHMKLJPFFFIGPKHXGPXZBBZBJHGHGHGHGHGHGHG";       // Serial Key

//--- Global Variables
int    h_indicator = INVALID_HANDLE;
string actual_path = "";
string active_sym  = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    ResetLastError();
    
    // 심볼 결정
    active_sym = (InpTargetSymbol == "") ? _Symbol : InpTargetSymbol;
    ENUM_TIMEFRAMES active_per = (InpTargetPeriod == PERIOD_CURRENT) ? _Period : InpTargetPeriod;

    actual_path = InpIndicatorPath;
    
    // 1차 시도
    h_indicator = CreateHandle(active_sym, active_per, actual_path);

    // 2차 시도 (Fallback)
    if(h_indicator == INVALID_HANDLE && GetLastError() == 4002) {
        if(StringFind(InpIndicatorPath, "Market\\") < 0) {
            actual_path = "Market\\" + InpIndicatorPath;
            ResetLastError();
            h_indicator = CreateHandle(active_sym, active_per, actual_path);
        }
    }

    if(h_indicator == INVALID_HANDLE) {
        PrintFormat("[ABC] 최종 오류: %s (%s) 로드 실패! 에러코드: %d", actual_path, active_sym, GetLastError());
        return INIT_FAILED;
    }

    PrintFormat("[ABC] %s 지표 로드 성공! (Symbol: %s, Handle: %d)", actual_path, active_sym, h_indicator);
    return INIT_SUCCEEDED;
}

//--- 핸들 생성 래퍼
int CreateHandle(string sym, ENUM_TIMEFRAMES per, string path) {
    return iCustom(sym, per, path,
                    InpDeviations,
                    InpMinimumBarRedraw,
                    InpShowAnalysisReport,
                    InpShowProfitValue,
                    InpAnalysisColor,
                    InpAnalysisLabel,
                    InpIndicatorRunFromICustom,
                    InpSerialKey);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    if(h_indicator != INVALID_HANDLE) IndicatorRelease(h_indicator);
    Comment(""); 
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if(h_indicator == INVALID_HANDLE) return;

    double middle = 0, upper = 0, lower = 0, arrowUp = 0, arrowDw = 0;
    double temp[1];
    
    // 데이터 복사
    if(CopyBuffer(h_indicator, 0, 0, 1, temp) > 0) middle = temp[0];
    if(CopyBuffer(h_indicator, 1, 0, 1, temp) > 0) upper  = temp[0];
    if(CopyBuffer(h_indicator, 4, 0, 1, temp) > 0) lower  = temp[0];
    if(CopyBuffer(h_indicator, 16, 0, 1, temp) > 0) arrowUp = temp[0];
    if(CopyBuffer(h_indicator, 17, 0, 1, temp) > 0) arrowDw = temp[0];

    //--- UI 출력 ---
    string uiMsg = "\n";
    uiMsg += "========================================\n";
    uiMsg += " [ABC] Indicator Monitor (v1.5)\n";
    uiMsg += "----------------------------------------\n";
    uiMsg += " Target : " + active_sym + " (" + EnumToString(_Period) + ")\n";
    uiMsg += " Path   : " + actual_path + "\n";
    uiMsg += "----------------------------------------\n";
    uiMsg += StringFormat(" Middle : %s\n", GetValStr(middle));
    uiMsg += StringFormat(" Upper  : %s\n", GetValStr(upper));
    uiMsg += StringFormat(" Lower  : %s\n", GetValStr(lower));
    uiMsg += "----------------------------------------\n";
    
    string signalMsg = "NONE";
    if(arrowUp != 0 && arrowUp != EMPTY_VALUE) signalMsg = "★ BUY SIGNAL ★";
    else if(arrowDw != 0 && arrowDw != EMPTY_VALUE) signalMsg = "▼ SELL SIGNAL ▼";
    
    uiMsg += " Signal : " + signalMsg + "\n";
    uiMsg += "----------------------------------------\n";
    uiMsg += " Update : " + TimeToString(TimeCurrent(), TIME_SECONDS) + "\n";
    uiMsg += "========================================\n";

    if(middle == 0 || middle == EMPTY_VALUE) {
        uiMsg += "\n [!] Status: SYNCING DATA...";
        uiMsg += "\n [!] Ensure " + active_sym + " is in Market Watch.";
    }

    Comment(uiMsg);
}

string GetValStr(double v) {
    if(v <= 0 || v == EMPTY_VALUE) return "---";
    return DoubleToString(v, _Digits);
}
