//+------------------------------------------------------------------+
//|                                             CIntervalWatcher.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Enum for different time sources                                  |
//+------------------------------------------------------------------+
enum ENUM_TIME_ORIGIN
  {
   TIME_ORIGIN_CURRENT = 0, // [0] Current Time
   TIME_ORIGIN_GMT,         // [1] GMT Time
   TIME_ORIGIN_LOCAL,       // [2] Local Time
   TIME_ORIGIN_TRADE_SERVER // [3] Server Time
  };
//+------------------------------------------------------------------+
//| class : CIntervalWatcher                                         |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : CIntervalWatcher                                   |
//| Type        : Report                                             |
//| Heritage    : No heredirary.                                     |
//| Description : Monitoring new time periods                        |
//|                                                                  |
//+------------------------------------------------------------------+
class CIntervalWatcher
  {
private:

   //--- Auxiliary attributes
   ulong             m_last_time;
   ulong             m_interval;
   ENUM_TIME_ORIGIN  m_time_origin;
   bool              m_first_return;
   
   //--- Get time by enum
   ulong             GetTime(ENUM_TIME_ORIGIN time_origin);
   
public:

                     CIntervalWatcher(ENUM_TIMEFRAMES interval, ENUM_TIME_ORIGIN time_origin = TIME_ORIGIN_CURRENT, bool first_return = true);
                     CIntervalWatcher(ulong interval, ENUM_TIME_ORIGIN time_origin = TIME_ORIGIN_CURRENT, bool first_return = true);
                     CIntervalWatcher(void);
                    ~CIntervalWatcher(void);
   
   //--- Setters
   void              SetInterval(ENUM_TIMEFRAMES interval);
   void              SetInterval(ulong interval);
   void              SetTimeOrigin(ENUM_TIME_ORIGIN time_origin);
   void              SetFirstReturn(bool first_return);
   
   //--- Getters
   ulong             GetInterval(void);
   ENUM_TIME_ORIGIN  GetTimeOrigin(void);
   bool              GetFirstReturn(void);
   ulong             GetLastTime(void);
   
   //--- Data
   bool              Inspect(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIntervalWatcher::CIntervalWatcher(ENUM_TIMEFRAMES interval, ENUM_TIME_ORIGIN time_origin = TIME_ORIGIN_CURRENT, bool first_return = true)
  {
   m_interval = PeriodSeconds(interval);
   m_time_origin = time_origin;
   m_first_return = first_return;
   m_last_time = 0;
  }
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIntervalWatcher::CIntervalWatcher(ulong interval, ENUM_TIME_ORIGIN time_origin = TIME_ORIGIN_CURRENT, bool first_return = true)
  {
   m_interval = interval;
   m_time_origin = time_origin;
   m_first_return = first_return;
   m_last_time = 0;
  }
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIntervalWatcher::CIntervalWatcher(void)
  {
   m_interval = 10; // 10 seconds
   m_time_origin = TIME_ORIGIN_CURRENT;
   m_first_return = true;
   m_last_time = 0;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CIntervalWatcher::~CIntervalWatcher(void)
  {
  }
//+------------------------------------------------------------------+
//| Get time in miliseconds                                          |
//+------------------------------------------------------------------+
ulong CIntervalWatcher::GetTime(ENUM_TIME_ORIGIN time_origin)
  {
   switch(time_origin)
     {
      case(TIME_ORIGIN_CURRENT):
        return(TimeCurrent());
      case(TIME_ORIGIN_GMT):
        return(TimeGMT());
      case(TIME_ORIGIN_LOCAL):
        return(TimeLocal());
      case(TIME_ORIGIN_TRADE_SERVER):
        return(TimeTradeServer());
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Set interval                                                     |
//+------------------------------------------------------------------+
void CIntervalWatcher::SetInterval(ENUM_TIMEFRAMES interval)
  {
   m_interval     = PeriodSeconds(interval);
  }
//+------------------------------------------------------------------+
//| Set interval                                                     |
//+------------------------------------------------------------------+
void CIntervalWatcher::SetInterval(ulong interval)
  {
   m_interval     = interval;
  }
//+------------------------------------------------------------------+
//| Set time origin                                                  |
//+------------------------------------------------------------------+
void CIntervalWatcher::SetTimeOrigin(ENUM_TIME_ORIGIN time_origin)
  {
   m_time_origin = time_origin;
  }
//+------------------------------------------------------------------+
//| Set initial return                                               |
//+------------------------------------------------------------------+
void CIntervalWatcher::SetFirstReturn(bool first_return)
  {
   m_first_return=first_return;
  }
//+------------------------------------------------------------------+
//| Get interval                                                     |
//+------------------------------------------------------------------+
ulong CIntervalWatcher::GetInterval(void)
  {
   return(m_interval);
  }
//+------------------------------------------------------------------+
//| Get time origin                                                  |
//+------------------------------------------------------------------+
ENUM_TIME_ORIGIN CIntervalWatcher::GetTimeOrigin(void)
  {
   return(m_time_origin);
  }
//+------------------------------------------------------------------+
//| Set initial return                                               |
//+------------------------------------------------------------------+
bool CIntervalWatcher::GetFirstReturn(void)
  {
   return(m_first_return);
  }
//+------------------------------------------------------------------+
//| Set last time                                                    |
//+------------------------------------------------------------------+
ulong CIntervalWatcher::GetLastTime(void)
  {
   return(m_last_time);
  }
//+------------------------------------------------------------------+
//| Check if there was an update                                     |
//+------------------------------------------------------------------+
bool CIntervalWatcher::Inspect(void)
  {
   //--- Get time
   ulong time_current = this.GetTime(m_time_origin);
   
   //--- First call, initial return
   if(m_last_time == 0)
     {
      m_last_time = time_current;
      return(m_first_return);
     }
   
   //--- Check interval
   if(time_current >= m_last_time + m_interval)
     {
      m_last_time = time_current;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
