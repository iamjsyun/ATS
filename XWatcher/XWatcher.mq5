//+------------------------------------------------------------------+
//|                                                     XWatcher.mq5 |
//|                                  Copyright 2026, Gemini CLI      |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini CLI"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input int      InpTimerInterval = 1;       // Scan Interval (seconds)
input int      InpFontSize      = 12;      // Font Size
input color    InpTextColor     = clrGold; // Text Color

//--- Global variables
string g_label_name = "XWatcher_Display";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   EventSetTimer(InpTimerInterval);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectDelete(0, g_label_name + "_BUY");
   ObjectDelete(0, g_label_name + "_SELL");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   int buy_count = 0, sell_count = 0;
   double buy_lots = 0, sell_lots = 0;

   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         long type = PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);

         if(type == POSITION_TYPE_BUY)
         {
            buy_count++;
            buy_lots += volume;
         }
         else if(type == POSITION_TYPE_SELL)
         {
            sell_count++;
            sell_lots += volume;
         }
      }
   }

   string buy_text = StringFormat("BUY  : %d : %.2f", buy_count, buy_lots);
   string sell_text = StringFormat("SELL : %d : %.2f", sell_count, sell_lots);

   UpdateLabel(g_label_name + "_BUY", buy_text, 50, 50);
   UpdateLabel(g_label_name + "_SELL", sell_text, 50, 50 + (InpFontSize + 5));
}

//+------------------------------------------------------------------+
//| Update Chart Label                                               |
//+------------------------------------------------------------------+
void UpdateLabel(string name, string text, int x, int y)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, InpTextColor);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ChartRedraw();
}
//+------------------------------------------------------------------+
