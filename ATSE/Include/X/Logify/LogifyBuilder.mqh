//+------------------------------------------------------------------+
//|                                                LogifyBuilder.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Import                                                           |
//+------------------------------------------------------------------+
#include "Logify.mqh"

//--- Creates an empty class to compile without errors
class CLogifyBuilder;

//+------------------------------------------------------------------+
//| class : CLogifyHandlerCommentBuilder                             |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : LogifyHandlerCommentBuilder                        |
//| Heritage    : No heritage                                        |
//| Description : Comment handler constructor.                       |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyHandlerCommentBuilder
  {
private:

   MqlLogifyHandleCommentConfig m_config;

   CLogifyBuilder    *m_parent;
   CLogifyFormatter  *m_formatter;
   CLogifyHandlerComment *m_handler;

public:
                     CLogifyHandlerCommentBuilder(CLogifyBuilder *logify);
                    ~CLogifyHandlerCommentBuilder(void);

   CLogifyHandlerCommentBuilder *SetLevel(ENUM_LOG_LEVEL level);
   CLogifyHandlerCommentBuilder *SetFormatter(string format);
   CLogifyHandlerCommentBuilder *SetFormatter(ENUM_LOG_LEVEL level, string format);
   CLogifyBuilder    *Done(void);
   //---
   CLogifyHandlerCommentBuilder *SetSize(int size);
   CLogifyHandlerCommentBuilder *SetFrameStyle(ENUM_LOG_FRAME_STYLE frame_style);
   CLogifyHandlerCommentBuilder *SetDirection(ENUM_LOG_DIRECTION direction);
   CLogifyHandlerCommentBuilder *SetTitle(string title);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder::CLogifyHandlerCommentBuilder(CLogifyBuilder *logify)
  {
   m_parent = logify;
   m_formatter = new CLogifyFormatter();
   m_handler = new CLogifyHandlerComment();

   m_handler.SetFormatter(GetPointer(m_formatter));
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder::~CLogifyHandlerCommentBuilder(void)
  {
  }
//+------------------------------------------------------------------+
//| Sets the log level for the handler.                              |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetLevel(ENUM_LOG_LEVEL level)
  {
   m_handler.SetLevel(level);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the default format string for the formatter.                |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetFormatter(string format)
  {
   m_formatter.SetFormat(format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets a log-level-specific format for the formatter.              |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetFormatter(ENUM_LOG_LEVEL level, string format)
  {
   m_formatter.SetFormat(level,format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Finalizes the handler configuration.                             |
//+------------------------------------------------------------------+
CLogifyBuilder *CLogifyHandlerCommentBuilder::Done(void)
  {
   delete GetPointer(this);
   m_parent.AddHandler(GetPointer(m_handler));
   return(m_parent);
  }
//+------------------------------------------------------------------+
//| Sets the size configuration of the comment handler.              |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetSize(int size)
  {
   m_config.size = size;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the frame style of the comment box.                         |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetFrameStyle(ENUM_LOG_FRAME_STYLE frame_style)
  {
   m_config.frame_style = frame_style;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the direction (UP or DOWN).                                 |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetDirection(ENUM_LOG_DIRECTION direction)
  {
   m_config.direction = direction;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the title of the comment box.                               |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyHandlerCommentBuilder::SetTitle(string title)
  {
   m_config.title = title;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| class : CLogifyHandlerConsoleBuilder                             |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : LogifyHandlerConsoleBuilder                        |
//| Heritage    : No heritage                                        |
//| Description : Console handler constructor.                       |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyHandlerConsoleBuilder
  {
private:

   CLogifyBuilder    *m_parent;
   CLogifyFormatter  *m_formatter;
   CLogifyHandlerConsole *m_handler;

public:
                     CLogifyHandlerConsoleBuilder(CLogifyBuilder *logify);
                    ~CLogifyHandlerConsoleBuilder(void);

   CLogifyHandlerConsoleBuilder *SetLevel(ENUM_LOG_LEVEL level);
   CLogifyHandlerConsoleBuilder *SetFormatter(string format);
   CLogifyHandlerConsoleBuilder *SetFormatter(ENUM_LOG_LEVEL level, string format);
   CLogifyBuilder    *Done(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyHandlerConsoleBuilder::CLogifyHandlerConsoleBuilder(CLogifyBuilder *logify)
  {
   m_parent = logify;
   m_formatter = new CLogifyFormatter();
   m_handler = new CLogifyHandlerConsole();

   m_handler.SetFormatter(GetPointer(m_formatter));
  };
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyHandlerConsoleBuilder::~CLogifyHandlerConsoleBuilder(void)
  {
  }
//+------------------------------------------------------------------+
//| Sets the log level for the handler.                              |
//+------------------------------------------------------------------+
CLogifyHandlerConsoleBuilder *CLogifyHandlerConsoleBuilder::SetLevel(ENUM_LOG_LEVEL level)
  {
   m_handler.SetLevel(level);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the default format string for the formatter.                |
//+------------------------------------------------------------------+
CLogifyHandlerConsoleBuilder *CLogifyHandlerConsoleBuilder::SetFormatter(string format)
  {
   m_formatter.SetFormat(format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets a log-level-specific format for the formatter.              |
//+------------------------------------------------------------------+
CLogifyHandlerConsoleBuilder *CLogifyHandlerConsoleBuilder::SetFormatter(ENUM_LOG_LEVEL level, string format)
  {
   m_formatter.SetFormat(level,format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Finalizes the handler configuration.                             |
//+------------------------------------------------------------------+
CLogifyBuilder    *CLogifyHandlerConsoleBuilder::Done(void)
  {
   m_parent.AddHandler(GetPointer(m_handler));
   delete GetPointer(this);
   return(m_parent);
  }
//+------------------------------------------------------------------+
//| class : CLogifyHandlerDatabaseBuilder                            |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : LogifyHandlerDatabaseBuilder                       |
//| Heritage    : No heritage                                        |
//| Description : Database handler constructor.                      |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyHandlerDatabaseBuilder
  {
private:

   MqlLogifyHandleDatabaseConfig m_config;

   CLogifyBuilder    *m_parent;
   CLogifyFormatter  *m_formatter;
   CLogifyHandlerDatabase *m_handler;

public:
                     CLogifyHandlerDatabaseBuilder(CLogifyBuilder *logify);
                    ~CLogifyHandlerDatabaseBuilder(void);

   CLogifyHandlerDatabaseBuilder *SetLevel(ENUM_LOG_LEVEL level);
   CLogifyHandlerDatabaseBuilder *SetFormatter(string format);
   CLogifyHandlerDatabaseBuilder *SetFormatter(ENUM_LOG_LEVEL level, string format);
   CLogifyBuilder    *Done(void);
   //---
   CLogifyHandlerDatabaseBuilder *SetDirectory(string directory);
   CLogifyHandlerDatabaseBuilder *SetBaseFileName(string base_filename);
   CLogifyHandlerDatabaseBuilder *SetMessagesPerFlush(int messages_per_flush);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder::CLogifyHandlerDatabaseBuilder(CLogifyBuilder *logify)
  {
   m_parent = logify;
   m_formatter = new CLogifyFormatter();
   m_handler = new CLogifyHandlerDatabase();

   m_handler.SetFormatter(GetPointer(m_formatter));
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder::~CLogifyHandlerDatabaseBuilder(void)
  {
  }
//+------------------------------------------------------------------+
//| Sets the log level for the handler.                              |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyHandlerDatabaseBuilder::SetLevel(ENUM_LOG_LEVEL level)
  {
   m_handler.SetLevel(level);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the default format string for the formatter.                |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyHandlerDatabaseBuilder::SetFormatter(string format)
  {
   m_formatter.SetFormat(format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets a log-level-specific format for the formatter.              |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyHandlerDatabaseBuilder::SetFormatter(ENUM_LOG_LEVEL level, string format)
  {
   m_formatter.SetFormat(level,format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Finalizes the handler configuration.                             |
//+------------------------------------------------------------------+
CLogifyBuilder    *CLogifyHandlerDatabaseBuilder::Done(void)
  {
   m_parent.AddHandler(GetPointer(m_handler));
   delete GetPointer(this);
   return(m_parent);
  }
//+------------------------------------------------------------------+
//| Sets the directory where the database files will be stored.      |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyHandlerDatabaseBuilder::SetDirectory(string directory)
  {
   m_config.directory = directory;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the base file name for the database file.                   |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyHandlerDatabaseBuilder::SetBaseFileName(string base_filename)
  {
   m_config.base_filename = base_filename;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets how many messages should be logged before flushing to disk. |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyHandlerDatabaseBuilder::SetMessagesPerFlush(int messages_per_flush)
  {
   m_config.messages_per_flush = messages_per_flush;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| class : CLogifyHandlerFileBuilder                                |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : LogifyHandlerFileBuilder                           |
//| Heritage    : No heritage                                        |
//| Description : File handler constructor.                          |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyHandlerFileBuilder
  {
private:

   MqlLogifyHandleFileConfig m_config;

   CLogifyBuilder    *m_parent;
   CLogifyFormatter  *m_formatter;
   CLogifyHandlerFile *m_handler;

public:
                     CLogifyHandlerFileBuilder(CLogifyBuilder *logify);
                    ~CLogifyHandlerFileBuilder(void);

   CLogifyHandlerFileBuilder *SetLevel(ENUM_LOG_LEVEL level);
   CLogifyHandlerFileBuilder *SetFormatter(string format);
   CLogifyHandlerFileBuilder *SetFormatter(ENUM_LOG_LEVEL level, string format);
   CLogifyBuilder    *Done(void);

   //---
   CLogifyHandlerFileBuilder *SetDirectory(string directory);
   CLogifyHandlerFileBuilder *SetFilename(string base_filename);
   CLogifyHandlerFileBuilder *SetFileExtension(ENUM_LOG_FILE_EXTENSION file_extension);
   CLogifyHandlerFileBuilder *SetRotationMode(ENUM_LOG_ROTATION_MODE rotation_mode);
   CLogifyHandlerFileBuilder *SetMessagesPerFlush(int messages_per_flush);
   CLogifyHandlerFileBuilder *SetCodepage(uint codepage);
   CLogifyHandlerFileBuilder *SetFileSizeMB(ulong max_file_size_mb);
   CLogifyHandlerFileBuilder *SetMaxFileCount(int max_file_count);

   //---
   CLogifyHandlerFileBuilder *ConfigNoRotation(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, int msg_per_flush=100, uint cp=CP_UTF8);
   CLogifyHandlerFileBuilder *ConfigDateRotation(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, int max_files=10, int msg_per_flush=100, uint cp=CP_UTF8);
   CLogifyHandlerFileBuilder *ConfigSizeRotation(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, ulong max_size=5, int max_files=10, int msg_per_flush=100, uint cp=CP_UTF8);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder::CLogifyHandlerFileBuilder(CLogifyBuilder *logify)
  {
   m_parent = logify;
   m_formatter = new CLogifyFormatter();
   m_handler = new CLogifyHandlerFile();

   m_handler.SetFormatter(GetPointer(m_formatter));
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder::~CLogifyHandlerFileBuilder(void)
  {
  }
//+------------------------------------------------------------------+
//| Sets the log level for the handler.                              |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetLevel(ENUM_LOG_LEVEL level)
  {
   m_handler.SetLevel(level);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the default format string for the formatter.                |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetFormatter(string format)
  {
   m_formatter.SetFormat(format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets a log-level-specific format for the formatter.              |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetFormatter(ENUM_LOG_LEVEL level, string format)
  {
   m_formatter.SetFormat(level,format);
   m_handler.SetFormatter(GetPointer(m_formatter));
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Finalizes the handler configuration.                             |
//+------------------------------------------------------------------+
CLogifyBuilder    *CLogifyHandlerFileBuilder::Done(void)
  {
   m_parent.AddHandler(GetPointer(m_handler));
   delete GetPointer(this);
   return(m_parent);
  }
//+------------------------------------------------------------------+
//| Sets the directory path where log files will be saved.           |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetDirectory(string directory)
  {
   m_config.directory = directory;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the base filename used for log files.                       |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetFilename(string base_filename)
  {
   m_config.base_filename = base_filename;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the file extension used for log files.                      |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetFileExtension(ENUM_LOG_FILE_EXTENSION file_extension)
  {
   m_config.file_extension = file_extension;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the rotation mode (none, by size, by date, etc).            |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetRotationMode(ENUM_LOG_ROTATION_MODE rotation_mode)
  {
   m_config.rotation_mode = rotation_mode;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets how many log messages should be written before flushing.    |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetMessagesPerFlush(int messages_per_flush)
  {
   m_config.messages_per_flush = messages_per_flush;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the character encoding (codepage) used for the log file.    |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetCodepage(uint codepage)
  {
   m_config.codepage = codepage;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the maximum size (in MB) before rotating the log file.      |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetFileSizeMB(ulong max_file_size_mb)
  {
   m_config.max_file_size_mb = max_file_size_mb;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Sets the maximum number of log files to keep (for rotation).     |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::SetMaxFileCount(int max_file_count)
  {
   m_config.max_file_count = max_file_count;
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Configures a file handler with no file rotation                  |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::ConfigNoRotation(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, int msg_per_flush=100, uint cp=CP_UTF8)
  {
   m_config.CreateNoRotationConfig(base_name,dir,extension,msg_per_flush,cp);
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Configures a file handler to rotate logs based on the date.      |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::ConfigDateRotation(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, int max_files=10, int msg_per_flush=100, uint cp=CP_UTF8)
  {
   m_config.CreateDateRotationConfig(base_name,dir,extension,max_files,msg_per_flush,cp);
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Configures a file handler to rotate logs when size is exceeded.  |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyHandlerFileBuilder::ConfigSizeRotation(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, ulong max_size=5, int max_files=10, int msg_per_flush=100, uint cp=CP_UTF8)
  {
   m_config.CreateSizeRotationConfig(base_name,dir,extension,max_size,max_files,msg_per_flush,cp);
   m_handler.SetConfig(m_config);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| class : CLogifyBuilder                                           |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : LogifyBuilder                                      |
//| Heritage    : No heritage                                        |
//| Description : Build CLogify objects, following the Builder design|
//|               pattern.                                           |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyBuilder
  {
private:

   CLogify           *m_logify;

public:
                     CLogifyBuilder(void);
                    ~CLogifyBuilder(void);

   CLogifyBuilder    *UseLanguage(ENUM_LOG_LANGUAGE language);

   //--- Starts configuration handlers
   CLogifyHandlerCommentBuilder *AddHandlerComment(void);
   CLogifyHandlerConsoleBuilder *AddHandlerConsole(void);
   CLogifyHandlerDatabaseBuilder *AddHandlerDatabase(void);
   CLogifyHandlerFileBuilder *AddHandlerFile(void);

   void              AddHandler(CLogifyHandler *handler);
   CLogify           *Build(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyBuilder::CLogifyBuilder(void)
  {
   m_logify = new CLogify();
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyBuilder::~CLogifyBuilder(void)
  {
  }
//+------------------------------------------------------------------+
//| Sets the language for the log                                    |
//+------------------------------------------------------------------+
CLogifyBuilder *CLogifyBuilder::UseLanguage(ENUM_LOG_LANGUAGE language)
  {
   m_logify.SetLanguage(language);
   return(GetPointer(this));
  }
//+------------------------------------------------------------------+
//| Starts configuration for a comment-based log handler.            |
//+------------------------------------------------------------------+
CLogifyHandlerCommentBuilder *CLogifyBuilder::AddHandlerComment(void)
  {
   return(new CLogifyHandlerCommentBuilder(GetPointer(this)));
  }
//+------------------------------------------------------------------+
//| Starts configuration for a console-based log handler.            |
//+------------------------------------------------------------------+
CLogifyHandlerConsoleBuilder *CLogifyBuilder::AddHandlerConsole(void)
  {
   return(new CLogifyHandlerConsoleBuilder(GetPointer(this)));
  }
//+------------------------------------------------------------------+
//| Starts configuration for a database-based log handler.           |
//+------------------------------------------------------------------+
CLogifyHandlerDatabaseBuilder *CLogifyBuilder::AddHandlerDatabase(void)
  {
   return(new CLogifyHandlerDatabaseBuilder(GetPointer(this)));
  }
//+------------------------------------------------------------------+
//| Starts configuration for a file-based log handler.               |
//+------------------------------------------------------------------+
CLogifyHandlerFileBuilder *CLogifyBuilder::AddHandlerFile(void)
  {
   return(new CLogifyHandlerFileBuilder(GetPointer(this)));
  }
//+------------------------------------------------------------------+
//| Adds a fully configured log handler to the current Logify object.|
//+------------------------------------------------------------------+
void CLogifyBuilder::AddHandler(CLogifyHandler *handler)
  {
   m_logify.AddHandler(handler);
  }
//+------------------------------------------------------------------+
//| Finalizes the build process and returns the configured Logify.   |
//+------------------------------------------------------------------+
CLogify *CLogifyBuilder::Build(void)
  {
   delete GetPointer(this);
   return(GetPointer(m_logify));
  }
//+------------------------------------------------------------------+
