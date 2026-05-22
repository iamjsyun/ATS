//+------------------------------------------------------------------+
//|                                                  NewBarEvent.mqh |
//|                                      Copyright 2022, Yuriy Bykov |
//|                              https://www.mql5.com/ru/code/38100/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Yuriy Bykov"
#property link      "https://www.mql5.com/ru/code/38100/"
#property version   "1.4"

#define ARRAY_APPEND(array, value)                  \
   ArrayResize(array, ArraySize(array) + 1, 128);   \
   array[ArraySize(array) - 1] = value;

#define ARRAY_FIND(array, value, i)          \
   for(i = 0; i < ArraySize(array); i++)     \
      if(array[i] == value) break;           \
   i = (i < ArraySize(array) ? i : -1);

class CSymbolNewBarEvent {
private:
   string            m_symbol;
   long              m_timeFrames[];
   long              m_timeLast[];
   bool              m_res[];
   int               Register(ENUM_TIMEFRAMES p_timeframe) {
      ARRAY_APPEND(m_timeFrames, p_timeframe);
      ARRAY_APPEND(m_timeLast, 0);
      ARRAY_APPEND(m_res, false);
      Update();
      return ArraySize(m_timeFrames) - 1;
   }

public:
                     CSymbolNewBarEvent(string p_symbol) : m_symbol(p_symbol) {}
   void              Update() {
      for(int i = 0; i < ArraySize(m_timeFrames); i++) {
         long time = iTime(m_symbol, (ENUM_TIMEFRAMES) m_timeFrames[i], 0);
         m_res[i] = (time != m_timeLast[i]);         
         m_timeLast[i] = time;
      }
   }

   bool              IsNewBar(ENUM_TIMEFRAMES p_timeframe) {
      int index;
      ARRAY_FIND(m_timeFrames, p_timeframe, index);

      if(index == -1) {
         Print("Register new event handler for " + m_symbol + " " + EnumToString(p_timeframe));
         index = Register(p_timeframe);
      }

      return m_res[index];
   }
};


class CNewBarEvent {
private:
   static CSymbolNewBarEvent     *m_symbolNewBarEvent[];
   static string                  m_symbols[];
   static int                     Register(string p_symbol)  {
      ARRAY_APPEND(m_symbols, p_symbol);
      CSymbolNewBarEvent *symbolNewBarEvent = new CSymbolNewBarEvent(p_symbol);
      ARRAY_APPEND(m_symbolNewBarEvent, symbolNewBarEvent);
      return ArraySize(m_symbols) - 1;
   }

public:
   static void              Update() {
      for(int i = 0; i < ArraySize(m_symbols); i++) {
         m_symbolNewBarEvent[i].Update();
      }
   }

   static bool              IsNewBar(string p_symbol, ENUM_TIMEFRAMES p_timeframe) {
      int index;
      ARRAY_FIND(m_symbols, p_symbol, index);
      if(index == -1) index = Register(p_symbol);
      return m_symbolNewBarEvent[index].IsNewBar(p_timeframe);
   }
};

CSymbolNewBarEvent* CNewBarEvent::m_symbolNewBarEvent[];
string CNewBarEvent::m_symbols[];

#undef ARRAY_APPEND
#undef ARRAY_FIND

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar(string p_symbol, ENUM_TIMEFRAMES p_timeframe) {
   return CNewBarEvent::IsNewBar(p_symbol, p_timeframe);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateNewBar() {
   CNewBarEvent::Update();
}
//+------------------------------------------------------------------+
