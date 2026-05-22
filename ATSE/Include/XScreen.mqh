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

class CXScreen : public CObject {

private:

public:
   //void                    Initialize();

   //void                    Output(string& text);
   //void                    Output(string& text, int lineNo,int col = 0,color clr=clrGold);
   //void                    Output(string& text[]);
   //void                    Output(CArrayList<string>& list);

   //void                    Out(int row, int col, string text, clr=clrGold);
   //void                    Output(int row,  string text, clr=clrGold) {



   
   int                     m_line_height ;
   int                     m_fontSize ;
   string                  m_fontName ;
   color                   m_color;
   int                     m_top ;
   int                     m_left;
   int                     m_width;
   int                     m_height;
   int                     m_count;

   CXScreen::CXScreen() {
      m_left = 10;
      m_top = 20;
      m_width = 600;
      m_height = 18;
      m_count = 25;
      Initialize();
   };

   CXScreen::CXScreen(int left , int top , int width , int height, int count ) {
      m_left = left;
      m_top = top;
      m_width = width;
      m_height = height;
      m_count = count;
      Initialize();
   };

   CXScreen::~CXScreen() {
   };

   void Initialize() {
      bool result = ChartSetInteger(0, CHART_SHOW_GRID, false);    
      m_fontSize = 14;
      m_fontName = "Consolas";
      int x = m_left, y = m_top, w = m_width, h = m_height;
      for(int row = 0 ; row < 20 ; row++) {
         for(int col = 0 ; col < 2 ; col++) {
            string objName = StringFormat("label%02d%02d",row,col);
            if (ObjectFind(0, objName) >= 0 ) ObjectDelete(0, objName);
            int left = x + (w * col);
            int top = y + (h * row);
            ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
            ObjectSetInteger(0, objName, OBJPROP_CORNER, 0);
            ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, left);
            ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, top);
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGold);
            ObjectSetString(0, objName, OBJPROP_FONT, m_fontName);
            ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, m_fontSize);
            //ObjectSetDouble(0,objName,OBJPROP_ANGLE,-45);
            ObjectSetString(0, objName, OBJPROP_TEXT, " ");
            ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, true);
         }
      }
   };

   void Empty(int row, int col ) {
      string objName = StringFormat("label%02d%02d",row,col);
      if (ObjectFind(0, objName) >= 0 ) {
         ObjectSetString(0, objName, OBJPROP_TEXT, " ");
         ChartRedraw(0);
      }
   };


   void SetXY(int left,int top) {
      m_left = left;
      m_top = top;
      Initialize();
   };

   void Output(int row,  string text, color clr=clrGold) {
      Output(row,0,text,clr);
   };

   void Output(int row, int col, string text, color clr=clrGold) {
      string objName = StringFormat("label%02d%02d",row,col);
      if (ObjectFind(0, objName) >= 0 ) {
         ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
         ObjectSetString(0, objName, OBJPROP_TEXT, text);
         ChartRedraw(0);
      }
   };
};


