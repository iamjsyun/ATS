//+------------------------------------------------------------------+
//|                                                        abcbb.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//| [v1.5] Septuple Bollinger Bands (7 Layers) Visualizer            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://github.com/google-gemini/gemini-cli"
#property version   "1.50"
#property strict

//--- INPUTS ---
input group             "--- Bollinger Bands Settings ---"
input int               InpBBPeriod     = 20;          // Average Period
input int               InpBBShift      = 0;           // Shift
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied Price

input group             "--- Deviations & Colors ---"
input double            InpDev1 = 1.0;  color InpClr1 = clrGray;         // Layer 1
input double            InpDev2 = 1.5;  color InpClr2 = clrDeepSkyBlue;  // Layer 2
input double            InpDev3 = 2.0;  color InpClr3 = clrYellow;       // Layer 3
input double            InpDev4 = 2.5;  color InpClr4 = clrWhite;       // Layer 4
input double            InpDev5 = 3.0;  color InpClr5 = clrRed;          // Layer 5
input double            InpDev6 = 3.5;  color InpClr6 = clrMagenta;      // Layer 6
input double            InpDev7 = 4.0;  color InpClr7 = clrDarkViolet;   // Layer 7

input group             "--- Visual Settings ---"
input int               InpLineWidth    = 1;              // Line Width
input int               InpMaxBars      = 10000;            // Max Bars to Draw

//--- Global Constants
#define BAND_COUNT 7

//--- Global Variables
int    h_bb[BAND_COUNT];
double devs[BAND_COUNT];
color  clrs[BAND_COUNT];
string m_prefix = "abcbb_";

// 버퍼를 관리할 구조체 (v1.4 Fix)
struct BBBuffer {
    double up[];
    double dw[];
};
BBBuffer buffers[BAND_COUNT];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    // 배열 초기화
    devs[0]=InpDev1; devs[1]=InpDev2; devs[2]=InpDev3; devs[3]=InpDev4; devs[4]=InpDev5; devs[5]=InpDev6; devs[6]=InpDev7;
    clrs[0]=InpClr1; clrs[1]=InpClr2; clrs[2]=InpClr3; clrs[3]=InpClr4; clrs[4]=InpClr5; clrs[5]=InpClr6; clrs[6]=InpClr7;

    for(int i=0; i<BAND_COUNT; i++) {
        h_bb[i] = iBands(_Symbol, _Period, InpBBPeriod, InpBBShift, devs[i], InpAppliedPrice);
        if(h_bb[i] == INVALID_HANDLE) {
            PrintFormat("[abcbb] 오류: 지표 핸들 %d 생성 실패!", i);
            return INIT_FAILED;
        }
    }

    ObjectsDeleteAll(0, m_prefix);
    ChartRedraw(0);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    for(int i=0; i<BAND_COUNT; i++) IndicatorRelease(h_bb[i]);
    ObjectsDeleteAll(0, m_prefix);
    Comment(""); 
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    int bars_available = iBars(_Symbol, _Period);
    int bars_to_draw = MathMin(InpMaxBars, bars_available - 1);
    if(bars_to_draw <= 1) return;

    double mid[];
    ArraySetAsSeries(mid, true);
    
    // 중앙선 복사
    int copied = CopyBuffer(h_bb[0], 0, 0, bars_to_draw, mid);
    if(copied <= 1) return;

    // 7개의 밴드 데이터 복사
    for(int b=0; b<BAND_COUNT; b++) {
        ArrayResize(buffers[b].up, copied); ArraySetAsSeries(buffers[b].up, true);
        ArrayResize(buffers[b].dw, copied); ArraySetAsSeries(buffers[b].dw, true);
        
        CopyBuffer(h_bb[b], 1, 0, copied, buffers[b].up);
        CopyBuffer(h_bb[b], 2, 0, copied, buffers[b].dw);
    }

    // 챠트 라인 업데이트
    for(int i=0; i < copied - 1; i++) {
        for(int b=0; b<BAND_COUNT; b++) {
            DrawBandSegment(IntegerToString(b)+"U", i, buffers[b].up[i], buffers[b].up[i+1], clrs[b]);
            DrawBandSegment(IntegerToString(b)+"D", i, buffers[b].dw[i], buffers[b].dw[i+1], clrs[b]);
        }
    }

    //--- UI 대시보드 ---
    string ui = "\n";
    ui += "========================================\n";
    ui += " [abcbb] Septuple BB Monitor (v1.5)\n";
    ui += "----------------------------------------\n";
    ui += StringFormat(" Middle : %.5f (Period: %d)\n", mid[0], InpBBPeriod);
    for(int b=BAND_COUNT-1; b>=0; b--) {
        ui += StringFormat(" Dev %.1f : %.5f / %.5f\n", devs[b], buffers[b].up[0], buffers[b].dw[0]);
    }
    ui += "----------------------------------------\n";
    ui += " Update : " + TimeToString(TimeCurrent(), TIME_SECONDS) + "\n";
    ui += "========================================\n";
    Comment(ui);

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| 밴드 라인 세그먼트 드로잉 유틸리티                                  |
//+------------------------------------------------------------------+
void DrawBandSegment(string suffix, int index, double val0, double val1, color clr) {
    datetime t0 = iTime(_Symbol, _Period, index);
    datetime t1 = iTime(_Symbol, _Period, index+1);
    if(t0 <= 0 || t1 <= 0) return;

    string name = m_prefix + suffix + IntegerToString(index);

    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_TREND, 0, t0, val0, t1, val1);
        ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, InpLineWidth);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
    } else {
        ObjectMove(0, name, 0, t0, val0);
        ObjectMove(0, name, 1, t1, val1);
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}
