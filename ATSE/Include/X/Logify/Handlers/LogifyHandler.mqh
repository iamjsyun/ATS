//+------------------------------------------------------------------+
//|                                                LogifyHandler.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Include files                                                    |
//+------------------------------------------------------------------+
#include "../LogifyModel.mqh"
#include "../Formatter/LogifyFormatter.mqh"
//+------------------------------------------------------------------+
//| class : CLogifyHandler                                           |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : CLogifyHandler                                     |
//| Heritage    : No heritage                                        |
//| Description : Base class for all log handlers.                   |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyHandler
  {
protected:
   
   string            m_name;
   ENUM_LOG_LEVEL    m_level;
   CLogifyFormatter  *m_formatter;
   
public:
                     CLogifyHandler(void);
                    ~CLogifyHandler(void);
   
   //--- Handler methods
   virtual void      Emit(MqlLogifyModel &data);         // Processes a log message and sends it to the specified destination
   virtual void      Flush(void);                        // Clears or completes any pending operations
   virtual void      Close(void);                        // Closes the handler and releases any resources
   
   //--- Set/Get
   void              SetLevel(ENUM_LOG_LEVEL level);
   void              SetFormatter(CLogifyFormatter *format);
   string            GetName(void);
   ENUM_LOG_LEVEL    GetLevel(void);
   CLogifyFormatter *GetFormatter(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyHandler::CLogifyHandler(void)
  {
   m_level = LOG_LEVEL_INFO;
   m_formatter = new CLogifyFormatter();
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyHandler::~CLogifyHandler(void)
  {
   //--- Delete formatter
   if(m_formatter != NULL)
     {
      delete m_formatter;
     }
  }
//+------------------------------------------------------------------+
//| Processes a log message and sends it to the specified destination|
//+------------------------------------------------------------------+
void CLogifyHandler::Emit(MqlLogifyModel &data)
  {
  }
//+------------------------------------------------------------------+
//| Clears or completes any pending operations                       |
//+------------------------------------------------------------------+
void CLogifyHandler::Flush(void)
  {
  }
//+------------------------------------------------------------------+
//| Closes the handler and releases any resources                    |
//+------------------------------------------------------------------+
void CLogifyHandler::Close(void)
  {
  }
//+------------------------------------------------------------------+
//| Set level                                                        |
//+------------------------------------------------------------------+
void CLogifyHandler::SetLevel(ENUM_LOG_LEVEL level)
  {
   m_level = level;
  }
//+------------------------------------------------------------------+
//| Set object formatter                                             |
//+------------------------------------------------------------------+
void CLogifyHandler::SetFormatter(CLogifyFormatter *format)
  {
   if(format != m_formatter)
     {
      delete m_formatter;
     }
   m_formatter = GetPointer(format);
  }
//+------------------------------------------------------------------+
//| Get name                                                         |
//+------------------------------------------------------------------+
string CLogifyHandler::GetName(void)
  {
   return(m_name);
  }
//+------------------------------------------------------------------+
//| Get level                                                        |
//+------------------------------------------------------------------+
ENUM_LOG_LEVEL CLogifyHandler::GetLevel(void)
  {
   return(m_level);
  }
//+------------------------------------------------------------------+
//| Get object formatter                                             |
//+------------------------------------------------------------------+
CLogifyFormatter *CLogifyHandler::GetFormatter(void)
  {
   return(m_formatter);
  }
//+------------------------------------------------------------------+