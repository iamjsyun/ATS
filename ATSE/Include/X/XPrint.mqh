//+------------------------------------------------------------------+
//|                                                       XPrint.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Arrays\Array.mqh>
#include <Arrays\ArrayObj.mqh>
#include <Arrays\List.mqh>
#include <Generic\ArrayList.mqh>
#include <Arrays\ArrayString.mqh>
#include <Trade\AccountInfo.mqh>

#include <Tools\DateTime.mqh>
#include <Strings\String.mqh>
#include <Generic\HashMap.mqh>

#include <Object.mqh>
#include <Generic\HashMap.mqh>
#include <Generic\Queue.mqh>
#include <Generic\Stack.mqh>
#include <Generic\ArrayList.mqh>

#include <Trade\Trade.mqh>
#include <JAson.mqh>



class CXPrint : public CObject {
private:

public:

   void                    Output(string& text);
   void                    Output(string& text, int lineNo,color clr=clrGold);
   void                    Output(string& text[]);
   void                    Output(CArrayList<string>& list);

   void                    SetX(int left);
   void                    SetY(int top);


   int                     m_top ;
   int                     m_left;
   int                     m_line_height ;
   int                     m_fontSize ;
   string                  m_fontName ;
   color                   m_color;

   CXPrint();
   ~CXPrint();
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CXPrint::CXPrint() {
   m_top = 30;
   m_left = 100;
   m_line_height = 22;
   m_fontSize = 14;
   m_fontName = "Consolas";

   string oName = "button01";
   int y = m_top ;
//   ObjectCreate(0, oName, OBJ_BUTTON, 0, 0, 0);
//   ObjectSetInteger(0, oName, OBJPROP_CORNER, 0);
//   ObjectSetInteger(0, oName, OBJPROP_XDISTANCE, m_left);
//   ObjectSetInteger(0, oName, OBJPROP_YDISTANCE, y);
//   ObjectSetInteger(0, oName, OBJPROP_COLOR, clrGold);
//   ObjectSetString(0, oName, OBJPROP_FONT, "Airal");
//   ObjectSetInteger(0, oName, OBJPROP_FONTSIZE, m_fontSize);
////ObjectSetDouble(0,objName,OBJPROP_ANGLE,-45);
//   ObjectSetString(0, oName, OBJPROP_TEXT, "XComment ");
//   ObjectSetInteger(0, oName, OBJPROP_SELECTABLE, true);
//   ObjectSetInteger(0, oName, OBJPROP_COLOR, clrRed);

   int w = 200, h = 30;
   ObjectSetInteger(0, oName, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, oName, OBJPROP_YSIZE, h);


   m_top = 60;
   int count = 15;
   for(int i = 0 ; i < count ; i++) {
      oName = StringFormat("obj%02d", i);
      if (ObjectFind(0, oName) >= 0 ) {
         ObjectDelete(0, oName);
      }
      y = m_top + m_line_height * i;
      ObjectCreate(0, oName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, oName, OBJPROP_CORNER, 0);
      ObjectSetInteger(0, oName, OBJPROP_XDISTANCE, m_left);
      ObjectSetInteger(0, oName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, oName, OBJPROP_COLOR, clrGold);
      ObjectSetString(0, oName, OBJPROP_FONT, m_fontName);
      ObjectSetInteger(0, oName, OBJPROP_FONTSIZE, m_fontSize);
      //ObjectSetDouble(0,objName,OBJPROP_ANGLE,-45);
      ObjectSetString(0, oName, OBJPROP_TEXT, " ");
      ObjectSetInteger(0, oName, OBJPROP_SELECTABLE, true);
      //ChartRedraw(0);

      //if ( oName == "obj10") {
      //   ObjectSetInteger(0, oName, OBJPROP_COLOR, clrRed);
      //}
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CXPrint::~CXPrint() {
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetX(int left) {
   
}

void SetY(int top) {
  
}


void CXPrint::Output(string &text, int lineNo, color clr = clrGold) {   
   string oName = StringFormat("obj%02d", lineNo);
   ObjectSetInteger(0, oName, OBJPROP_COLOR, clrGold);
   ObjectSetString(0, oName, OBJPROP_TEXT, text);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void CXPrint::Output(string &text[]) {
}


void CXPrint::Output(CArrayList<string>& list) {
   int count = list.Count();
   for(int i = 0 ; i < count ; i++) {
      string oName = StringFormat("obj%02d", i);
      if (ObjectFind(0, oName) >= 0 ) {
         string text;
         list.TryGetValue(i, text);
         ObjectSetString(0, oName, OBJPROP_TEXT, text);
      }
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
