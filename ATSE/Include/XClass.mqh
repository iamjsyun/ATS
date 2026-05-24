//+------------------------------------------------------------------+
//|                                                      CXClass.mqh |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

#include <JAson.mqh>
#include <XPrint.mqh>
#include <math_utils.mqh>
#include <socket-library-mt4-mt5.mqh>



template<typename T>
void ArrayAdd(T &array[],   const T elem, int reserve = 0) {
   int size = ArraySize(array);
   if(!(bool)ArrayResize(array, size + 1, reserve))  return;
   array[size] = elem;
}

template<typename T>
void ArrayAdd(T &array[], const T &elem, int reserve = 0  ) {
   int size = ArraySize(array);
   if(!(bool)ArrayResize(array, size + 1, reserve))  return;
   array[size] = elem;
}

template<typename T>
void ArrayAdd(T &array[], const  T &array_add[], int reserve = 0) {
   int i, j;
   int size1 = ArraySize(array);
   int size2 = ArraySize(array_add);
   ArrayResize(array, size1 + size2, reserve);
   for(i = size1, j = 0; j < size2; i++, j++)
      array[i] = array_add[j];
}


//=============================/ ArrayDelElement /=============================================
template<typename T>
void ArrayDel(T &array[], int pos, int length = 1) {
   int size = ArraySize(array);
   int i, j;
   for(i = pos, j = pos + length; j < size; i++, j++)
      array[i] = array[j];
   ArrayResize(array, size - length);
}
//=============================/ ArrayMaxValue /=============================================
template<typename T>
T ArrayMaxValue(const T &array[], int pos = 0, int length = -1) {
   if(length < 0)
      length = WHOLE_ARRAY;
   return array[ArrayMaximum(array, length, pos)];
}
//=============================/ ArrayMinValue /=============================================
template<typename T>
T ArrayMinValue(const T &array[], int pos = 0, int length = -1) {
   if(length < 0)
      length = WHOLE_ARRAY;
   return array[ArrayMinimum(array, length, pos)];
}
//=============================/ ArrayLast /=============================================
template<typename T>
T ArrayLast(const T &array[]) {
   return array[ArraySize(array) - 1];
}
//=============================/ ArrayLast /=============================================
template<typename T>
T ArrayFirst(const T &array[]) {
   return array[0];
}
//=============================/ ArrayToString /=============================================
template<typename T>
string ArrayToString(const T &array[], int pos=0, int length = -1, string delimeter = " ") {
   int last = (length < 0) ? ArraySize(array) : length + pos;
   string str;
   for(int i = pos; i < last; i++)
      str += string(array[i]) + delimeter;
   return str;
}




//=============================/ ArrayToString /=============================================
template<typename T>
bool ArrayEmpty(const T &array[]) {
   return bool(ArraySize(array));
}
//=============================/ ArrayReverse /=============================================
template<typename T>
void ArrayReverse(T &array[]) {
   int i, j;
   for(i = 0, j = ArraySize(array) - 1; i < j; i++, j--)
      MathSwap(array[i], array[j]);
}

template<typename T>
bool ArrayContains(T &array[], T value ) {
   bool result = false;
   for(int i = 0 ; i < ArraySize(array) - 1 ; i++) {
      if (array[i] == value) {
         result = true;
         break;
      }
   }
   return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool       ChartShowGridGet(bool &result, const long chart_ID = 0) {
   long value;
   ResetLastError();
   if(!ChartGetInteger(chart_ID, CHART_SHOW_GRID, 0, value)) {
      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
      return(false);
   }
   result = value;
   return(true);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool       ChartShowGridSet(const bool value, const long chart_ID = 0) {
   ResetLastError();
   if(!ChartSetInteger(chart_ID, CHART_SHOW_GRID, 0, value)) {

      Print(__FUNCTION__ + ", Error Code = ", GetLastError());
      return(false);
   }
   return(true);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string     TimeToISO(datetime time) {
   MqlDateTime t;
   TimeToStruct(time, t);
   string s1 = StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ", t.year, t.mon, t.day, t.hour, t.min, t.sec);
   return s1;
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime   ISOToTime(string isoTime) {
   StringReplace(isoTime, "T", " ");
   StringReplace(isoTime, "Z", "");
   datetime time = StringToTime(isoTime);
   return time;
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string     Now(void) {
   return TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
};

class CXNewBar {
//https://www.mql5.com/en/forum/385438
private:
   string            m_symbol;
   ENUM_TIMEFRAMES   m_tf;
   datetime          m_lastBarOpenedAt;
   datetime          m_time[1];
public:
   CXNewBar(string symbol, ENUM_TIMEFRAMES tf) {
      m_symbol = symbol;
      m_tf = tf;
      CopyTime(m_symbol, m_tf, 0, 1, m_time);
      m_lastBarOpenedAt = m_time[0];
   }
   ~CXNewBar() {}
   bool              isNewBar() {
      CopyTime(m_symbol, m_tf, 0, 1, m_time);
      if(m_lastBarOpenedAt < m_time[0]) {
         m_lastBarOpenedAt = m_time[0];
         return(true);
      } else {
         return(false);
      }
   }
};

//
//class CXLogger : public CObject {
//public:
//
//   int                  m_handle;
//   string               m_prefix;
//   string               m_fileName;
//   ulong                m_seq;
//   string               m_fmt;
//   bool                 m_flush;
//
//   void              Initialize(string prefix = "LOG", string option = "YMDH") {
//      Close();
//      MqlDateTime time = {};
//      TimeToStruct(TimeCurrent(), time);
//      if (StringCompare(option, "YMD", false) == 0 ) {
//         m_fileName = StringFormat("%s-%04d%02d%02d.TXT", prefix, time.year, time.mon, time.day);
//      }
//      if (StringCompare(option, "YMDH", false) == 0 ) {
//         m_fileName = StringFormat("%s-%04d%02d%02d-%02d0000.TXT", prefix, time.year, time.mon, time.day, time.hour);
//      }
//      if (StringCompare(option, "YMDHM", false) == 0 ) {
//         m_fileName = StringFormat("%s-%04d%02d%02d-%02d%02d00.TXT", prefix, time.year, time.mon, time.day, time.hour, time.min);
//      }
//      if (StringCompare(option, "YMDHMS", false) == 0 ) {
//         m_fileName = StringFormat("%s-%04d%02d%02d-%02d%02d%02d.TXT", prefix, time.year, time.mon, time.day, time.hour, time.min, time.sec);
//      }
//      m_fileName = StringFormat("%s-%04d%02d%02d.LOG", prefix, time.year, time.mon, time.day);
//      m_handle = FileOpen(m_fileName, FILE_IS_TEXT | FILE_SHARE_READ | FILE_SHARE_WRITE );
//   };
//
//
//   void              Info(string text = "") {
//      Write(text, "I");
//   };
//   void              Trace(string text = "") {
//      Write(text, "T");
//   };
//   void              Debug(string text = "") {
//      Write(text, "D");
//   };
//   void              Error(string text = "") {
//      Write(text, "E");
//   };
//
//   void              Flush(void) {
//      if (m_handle != INVALID_HANDLE) FileFlush(m_handle);
//   };
//
//   CXLogger() {
//      m_prefix = "LOG";
//   };
//
//   ~CXLogger() {
//      this.Close();
//   };
//
//   static string     LogOnce(string text, string fileName = "") {
//      static int seq;
//      if (StringLen(fileName) <= 0) {
//         MqlDateTime t;
//         TimeToStruct(TimeCurrent(), t);
//         fileName = StringFormat("TEMP-%04d%02d%02d %02d%02d%02d %06d.TXT", t.year, t.mon, t.day, t.hour, t.min, t.sec, seq++);
//      }
//
//      int handle = FileOpen(fileName, FILE_IS_TEXT | FILE_SHARE_READ | FILE_SHARE_WRITE );
//      if (handle != INVALID_HANDLE) {
//         string s1 = StringFormat("%s : %s", TimeToString(TimeCurrent(), TIME_DATE), text);
//         FileWrite(handle, text);
//         FileFlush(handle);
//         FileClose(handle);
//      }
//      return fileName;
//   };
//
//protected:
//
//   void              Write(string text = "", string type = "I") {
//      if (StringLen(text) <= 0 ) return;
//      string s1 = StringFormat("%s {%s]  %s", TimeToString(TimeCurrent(), TIME_DATE), type, text);
//      if (m_handle != INVALID_HANDLE) {
//         FileWrite(m_handle, s1);
//         if (m_flush) FileFlush(m_handle);
//      }
//   };
//
//   void              Close(void) {
//      if (m_handle != INVALID_HANDLE) {
//         FileFlush(m_handle);
//         FileClose(m_handle);
//      }
//   };
//};
//
//
//class CXClass : public CObject {
//public:
//  
//
//   static string     Now(void) {
//      return TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
//   };
//};
//
//class CXScreen : public CObject {
//public:
//   void              XY(string text, int row, color clr = clrGold) {
//      Output(text, row, clr);
//   };
//
//   //void              XY(string& text, int row, color clr = clrGold) {
//   //   Output(text, row, clr);
//   //};
//
//   void              XY(string& texts[], int row,  color clr = clrGold) {
//      Output(texts, row, clr);
//   };
//
//   void              Init( int top = 10, int left = 100, int height = 22, int size = 14, string fontName = "Consolas") {
//      Initialize(top, left, height, size, fontName);
//   };
//   CXScreen() {
//      Initialize();
//   };
//   ~CXScreen() {};
//
//protected:
//
//   int                  m_count;
//   int                  m_top;
//   int                  m_left;
//   int                  m_line_height;
//   int                  m_fontSize;
//   string               m_fontName;
//   string               m_oName;
//
//   void              Initialize(int top = 10, int left = 100, int height = 22, int size = 14, string fontName = "Consolas") {
//      m_top = top;
//      m_left = left;
//      m_line_height = height;
//      m_fontSize = size;
//      m_fontName = fontName;
//
//      m_count = 30;
//
//      for(int i = 0 ; i < m_count ; i++) {
//         m_oName = StringFormat("obj%03d", i);
//         if (ObjectFind(0, m_oName) >= 0 ) {
//            ObjectDelete(0, m_oName);
//         }
//         int y = m_top + m_line_height * i;
//         ObjectCreate(0, m_oName, OBJ_LABEL, 0, 0, 0);
//         ObjectSetInteger(0, m_oName, OBJPROP_CORNER, 0);
//         ObjectSetInteger(0, m_oName, OBJPROP_XDISTANCE, m_left);
//         ObjectSetInteger(0, m_oName, OBJPROP_YDISTANCE, y);
//         ObjectSetInteger(0, m_oName, OBJPROP_COLOR, clrGold);
//         ObjectSetString(0, m_oName, OBJPROP_FONT, m_fontName);
//         ObjectSetInteger(0, m_oName, OBJPROP_FONTSIZE, m_fontSize);
//         //ObjectSetDouble(0,objName,OBJPROP_ANGLE,-45);
//         ObjectSetString(0, m_oName, OBJPROP_TEXT, " ");
//         ObjectSetInteger(0, m_oName, OBJPROP_SELECTABLE, true);
//         //ChartRedraw(0);
//
//         //if ( oName == "obj10") {
//         //   ObjectSetInteger(0, oName, OBJPROP_COLOR, clrRed);
//         //}
//      }
//   };
//
//   void              Output(string text, int row, int col, color clr = clrGold) {
//      if (StringLen(text) <= 0 || text == NULL) text = " ";
//      m_oName = StringFormat("obj%03d", row);
//      ObjectSetInteger(0, m_oName, OBJPROP_COLOR, clr);
//      ObjectSetString(0, m_oName, OBJPROP_TEXT, text);
//      ChartRedraw(0);
//   };
//
//   void              Output(string& texts[], int row, int col, color clr = clrGold) {
//      if (ArraySize(texts) <= 0 ) return;
//      for(int i = 0 ; i < ArraySize(texts) - 1 ; i++ ) {
//         if (StringLen(texts[i]) <= 0 || texts[i] == NULL) continue;
//
//         m_oName = StringFormat("obj%03d", row);
//         ObjectSetInteger(0, m_oName, OBJPROP_COLOR, clr);
//         ObjectSetString(0, m_oName, OBJPROP_TEXT, texts[i]);
//         ChartRedraw(0);
//      }
//   };
//};
//
//


class CXObject : CObject {
public:
   long                 m_id;
   long                 m_type;
   string               m_typeName;
   string               m_symbol;
   double               m_price;
   double               m_tp;
   double               m_sl;
   double               m_profit;
   double               m_lot;
   datetime             m_time;
   string               m_timeISO;
   string               m_comment;
   ulong                m_magic;
   ulong                m_ticket;
   string               m_eaName;
   ulong                m_index;
   string               m_tag;
   long                 m_account;
   long                 m_seq;
   string               m_typeDescrition;
   
   CJAVal               m_json;
   
   CXObject() {
      m_id = 0;
      m_magic = 0;
      m_index = 0;
      m_seq = 0;
   }
   
//
//   virtual void      Object_To_Json(CJAVal& json) {
//      json["Id"] = m_id;
//      json["Type"] = m_type;
//      json["TypeName"] = m_typeName;
//      json["Symbol"] = m_symbol;
//      json["Price"] = m_price;
//      json["TP"] = m_tp;
//      json["SL"] = m_sl;
//      json["Profit"] = m_profit;
//      json["Lot"] = m_lot;
//      json["Time"] = m_time;
//      json["ticket"] = m_ticket;
//      json["Magic"] = m_magic;
//      json["Comment"] = m_comment;
//      json["Tag"] = m_tag;
//   };
//
//   virtual string    Object_To_JsonString(void) {
//      Object_To_Json(m_json);
//      string jt = m_json.Serialize();
//      return jt;
//   };
//
//   virtual void      String_To_Object(string str) {
//      CJAVal json;
//      json.Deserialize(str);
//      m_json.Clear();
//
//      m_json["Id"] = json["Id"].ToInt();
//      m_json["Type"] = json["Type"].ToInt();
//      m_json["TypeName"] = json["TypeName"].ToStr();
//      m_json["Symbol"] = json["Symbol"].ToStr();
//      m_json["Price"] = json["Price"].ToDbl();
//      m_json["TP"] = json["TP"].ToDbl();
//      m_json["SL"] = json["SL"].ToDbl();
//      m_json["Profit"] = json["Profit"].ToDbl();
//      m_json["Lot"] = json["Lot"].ToDbl();
//      //m_json["Time"] = m_time;
//      m_json["ticket"] = json["Ticket"].ToInt();;
//      m_json["Magic"] = json["Magic"].ToInt();;
//      m_json["Comment"] = json["Comment"].ToStr();
//      m_json["Tag"] = json["Tag"].ToStr();
//
//      m_id = json["Id"].ToInt();
//      m_type = json["Type"].ToInt();
//      m_typeName = json["TypeName"].ToStr();
//      m_symbol = json["Symbol"].ToStr();
//      m_price = json["Pricel"].ToDbl();
//      m_ticket = json["Ticket"].ToInt();
//      m_magic = json["Magic"].ToInt();
//      m_comment = json["Comment"].ToStr();
//      m_tag = json["Tag"].ToStr();
//
//      string stime = json["Time"].ToStr();
//      StringReplace(stime, "T", " ");
//      StringReplace(stime, "Z", "");
//      //m_time = StringToTime(stime);
//
//   };
};


class CXContextObject : CObject {

public:

   long              m_magic;
   string            m_strs[30];

   CXContextObject() {
   };
   ~CXContextObject() {
   };

   virtual void      OnTimer(void) {
   }

   virtual void      Initialize(string ip = "127.0.0.1", int port = 2025) {
      this.m_ip = ip;
      this.m_port = (ushort)port;
      m_client = new ClientSocket(m_ip, m_port);
      m_magic = 2025;
   }

   virtual void      SetMagicNo(long magic = 2025) {
      m_magic =         magic;
   };
   virtual long      GetMagicNo(void) {
      return m_magic;
   };

   virtual void      Send(string text) {

      if (!m_client.IsSocketConnected()) {
         m_client = new ClientSocket(m_ip, m_port);
      }
      m_client.Send(text);
   };


   virtual string    Recv(void) {
      if (!m_client.IsSocketConnected()) return NULL;
      string rs = m_client.Receive();
      return rs;
   };

   virtual void Pulse(string msg = "Pulse") {
      static int seq;
      string s1 = StringFormat("SEQ : %d  %s", seq++, msg);
      Send(s1);
   };




protected:
   ClientSocket*           m_client;
   string                  m_ip;
   ushort                  m_port;
   CXObject                m_obj;
};






//
//
//class CXItem : CObject {
//public:
//   long                 m_id;
//   long                 m_type;
//   string               m_typeName;
//   string               m_symbol;
//   double               m_price;
//   double               m_tp;
//   double               m_sl;
//   double               m_profit;
//   double               m_lot;
//   datetime             m_time;
//   string               m_comment;
//   long                 m_magic;
//   long                 m_ticket;
//   string               m_eaName;
//   ulong                m_index;
//   string               m_tag;
//   CJAVal               m_json;
//
//   void ToJson(CJAVal& json) {
//      json["Id"] = m_id;
//      json["Type"] = m_type;
//      json["TypeName"] = m_typeName;
//      json["Symbol"] = m_symbol;
//      json["Price"] = m_price;
//      json["TP"] = m_tp;
//      json["SL"] = m_sl;
//      json["Profit"] = m_profit;
//      json["Lot"] = m_lot;
//      json["Time"] = CXClass::TimeToISO(m_time);
//      json["ticket"] = m_ticket;
//      json["Magic"] = m_magic;
//      json["Comment"] = m_comment;
//   };
//
//   string ToJsonString() {
//      return m_json.Serialize();
//   };
//
//
//   void ToObject(string jsonText) {
//      m_json.Deserialize(jsonText);
//      m_id = m_json["Id"].ToInt();
//      m_type = m_json["Type"].ToInt();
//      m_type = m_json["TypeName"].ToInt();
//      m_symbol = m_json["Symbol"].ToStr();
//      m_price = m_json["Price"].ToDbl();
//      m_tp = m_json["TP"].ToDbl();
//      m_sl = m_json["SL"].ToDbl();
//      m_profit = m_json["Profit"].ToDbl();
//      m_lot = m_json["Lot"].ToDbl();
//      //m_time = m_json["Time"].ToStr();
//      m_ticket = m_json["Ticket"].ToInt();
//      m_magic = m_json["Magic"].ToInt();
//      m_comment = m_json["Comment"].ToStr();
//      m_tag = m_json["Tag"].ToStr();
//   };
//};
//
//class CXPacket : CObject {
//
//public:
//   long                 m_account;
//   int                  m_accountType;
//   string               m_accountTypeName;
//   string               m_cmd;
//   CJAVal               m_items;
//
//   void ToJson(CJAVal& json) {
//      json["Account"] = m_account;
//      json["AccountType"] = m_accountType;
//      json["AccountTypeName"] = m_accountTypeName;
//      json["Cmd"] = m_cmd;
//      json["Items"].Add(m_items);
//   };
//
//   string  ToJsonString(void) {
//      CJAVal json;
//      ToJson(json);
//      string result = json.Serialize();
//      return result;
//   };
//
//   void ToObject(string jsonText) {
//   };
//
//
//};
//
//
//class CXMaster : public CObject {
//public:
//   ClientSocket*           m_sock;
//   string                  m_ip;
//   ushort                  m_port;
//   bool                    m_saveLog;
//   void Initialize(string ip = "127.0.0.1", int port = 2222, bool saveLog = false) {
//      m_ip = ip;
//      m_port = (ushort)port;
//      m_sock = new ClientSocket(m_ip,m_port);
//      m_saveLog = saveLog;
//   };
//
//
//   void Send(string& data, bool saveLog = false) {
//
//      if (!m_sock.IsSocketConnected()) {
//         m_sock = new ClientSocket(m_ip,m_port);
//      }
//
//      m_sock.Send(data );
//
//      static int cntLog;
//      if (saveLog ) {
//         //MqlDateTime time = {};
//         //TimeToStruct(TimeCurrent(),time);
//         //string filename = StringFormat("JSON-%04d%02d%02d-%02d%02d%02d.TXT",time.year,time.mon,time.day,time.hour,time.min,time.sec);
//         //m_handle = FileOpen(filename,FILE_IS_TEXT | FILE_WRITE);
//         //FileWriteString(fileHandle,data);
//         //FileFlush(fileHandle);
//         //FileClose(fileHandle);
//         cntLog++;
//      }
//   };
//
//   string Recv(void) {
//      int rc = 0;
//      string rs = m_sock.Receive();
//      Print(rs);
//
//
////      do {
////         uchar receivedData[];
////         rc = m_sock.Receive(receivedData);
////         // Add the receivedData[] to some sort of store...
////      } while (rc > 0);
////
//
//      return rs;
//   };
//};
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+



#include <XScreen.mqh>
CXScreen xs;
CXLogger xl;