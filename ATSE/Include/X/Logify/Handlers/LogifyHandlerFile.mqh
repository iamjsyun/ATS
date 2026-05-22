//+------------------------------------------------------------------+
//|                                            LogifyHandlerFile.mqh |
//|                                                     joaopedrodev |
//|                       https://www.mql5.com/en/users/joaopedrodev |
//+------------------------------------------------------------------+
#property copyright "joaopedrodev"
#property link      "https://www.mql5.com/en/users/joaopedrodev"
//+------------------------------------------------------------------+
//| Include files                                                    |
//+------------------------------------------------------------------+
#include "LogifyHandler.mqh"
#include "../Utils/IntervalWatcher.mqh"
//+------------------------------------------------------------------+
//| ENUMS for log rotation and file extension                        |
//+------------------------------------------------------------------+
enum ENUM_LOG_ROTATION_MODE
  {
   LOG_ROTATION_MODE_NONE = 0,       // No rotation
   LOG_ROTATION_MODE_DATE,           // Rotate based on date
   LOG_ROTATION_MODE_SIZE,           // Rotate based on file size
  };
enum ENUM_LOG_FILE_EXTENSION
  {
   LOG_FILE_EXTENSION_TXT = 0,       // .txt file
   LOG_FILE_EXTENSION_LOG,           // .log file
   LOG_FILE_EXTENSION_JSON,          // .json file
  };
//+------------------------------------------------------------------+
//| Struct: MqlLogifyHandleFileConfig                                |
//+------------------------------------------------------------------+
struct MqlLogifyHandleFileConfig
  {
   string directory;                         // Directory for log files
   string base_filename;                     // Base file name
   ENUM_LOG_FILE_EXTENSION file_extension;   // File extension type
   ENUM_LOG_ROTATION_MODE rotation_mode;     // Rotation mode
   int messages_per_flush;                   // Messages before flushing
   uint codepage;                            // Encoding (e.g., UTF-8, ANSI)
   ulong max_file_size_mb;                   // Max file size in MB for rotation
   int max_file_count;                       // Max number of files before deletion
   
   //--- Default constructor
   MqlLogifyHandleFileConfig(void)
     {
      directory = "logs";                    // Default directory
      base_filename = "expert";              // Default base name
      file_extension = LOG_FILE_EXTENSION_LOG;// Default to .log extension
      rotation_mode = LOG_ROTATION_MODE_SIZE;// Default size-based rotation
      messages_per_flush = 100;              // Default flush threshold
      codepage = CP_UTF8;                    // Default UTF-8 encoding
      max_file_size_mb = 5;                  // Default max file size in MB
      max_file_count = 10;                   // Default max file count
     }
   
   //--- Destructor
   ~MqlLogifyHandleFileConfig(void)
     {
     }

   //--- Create configuration for no rotation
   void CreateNoRotationConfig(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, int msg_per_flush=100, uint cp=CP_UTF8)
     {
      directory = dir;
      base_filename = base_name;
      file_extension = extension;
      rotation_mode = LOG_ROTATION_MODE_NONE;
      messages_per_flush = msg_per_flush;
      codepage = cp;
     }

   //--- Create configuration for date-based rotation
   void CreateDateRotationConfig(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, int max_files=10, int msg_per_flush=100, uint cp=CP_UTF8)
     {
      directory = dir;
      base_filename = base_name;
      file_extension = extension;
      rotation_mode = LOG_ROTATION_MODE_DATE;
      messages_per_flush = msg_per_flush;
      codepage = cp;
      max_file_count = max_files;
     }

   //--- Create configuration for size-based rotation
   void CreateSizeRotationConfig(string base_name="expert", string dir="logs", ENUM_LOG_FILE_EXTENSION extension=LOG_FILE_EXTENSION_LOG, ulong max_size=5, int max_files=10, int msg_per_flush=100, uint cp=CP_UTF8)
     {
      directory = dir;
      base_filename = base_name;
      file_extension = extension;
      rotation_mode = LOG_ROTATION_MODE_SIZE;
      messages_per_flush = msg_per_flush;
      codepage = cp;
      max_file_size_mb = max_size;
      max_file_count = max_files;
     }
   
   //--- Validate configuration
   bool ValidateConfig(string &error_message)
     {
      //--- Saves the return value
      bool is_valid = true;
      
      //--- Check if the directory is not empty
      if(directory == "")
        {
         directory = "logs";
         error_message = "The directory cannot be empty.";
         is_valid = false;
        }
      
      //--- Check if the base filename is not empty
      if(base_filename == "")
        {
         base_filename = "expert";
         error_message = "The base filename cannot be empty.";
         is_valid = false;
        }
      
      //--- Check if the number of messages per flush is positive
      if(messages_per_flush <= 0)
        {
         messages_per_flush = 100;
         error_message = "The number of messages per flush must be greater than zero.";
         is_valid = false;
        }
      
      //--- Check if the codepage is valid (verify against expected values)
      if(codepage != CP_ACP
      && codepage != CP_MACCP
      && codepage != CP_OEMCP
      && codepage != CP_SYMBOL
      && codepage != CP_THREAD_ACP
      && codepage != CP_UTF7
      && codepage != CP_UTF8)
        {
         codepage = CP_UTF8;
         error_message = "The specified codepage is invalid.";
         is_valid = false;
        }
      
      //--- Validate limits for size-based rotation
      if(rotation_mode == LOG_ROTATION_MODE_SIZE)
        {
         if(max_file_size_mb <= 0)
           {
            max_file_size_mb = 5;
            error_message = "The maximum file size (in MB) must be greater than zero.";
            is_valid = false;
           }
         if(max_file_count <= 0)
           {
            max_file_count = 10;
            error_message = "The maximum number of files must be greater than zero.";
            is_valid = false;
           }
        }
      
      //--- Validate limits for date-based rotation
      if(rotation_mode == LOG_ROTATION_MODE_DATE)
        {
         if(max_file_count <= 0)
           {
            max_file_count = 10;
            error_message = "The maximum number of files for date-based rotation must be greater than zero.";
            is_valid = false;
           }
        }
   
      //--- No errors found
      return(is_valid);
     }
  };
//+------------------------------------------------------------------+
//| class : CLogifyHandlerFile                                       |
//|                                                                  |
//| [PROPERTY]                                                       |
//| Name        : CLogifyHandlerFile                                 |
//| Heritage    : CLogifyHandler                                     |
//| Description : Log handler, inserts data into terminal window.    |
//|                                                                  |
//+------------------------------------------------------------------+
class CLogifyHandlerFile : public CLogifyHandler
  {
private:
   //--- Config
   MqlLogifyHandleFileConfig m_config;
   
   //--- Update utilities
   CIntervalWatcher  m_interval_watcher;
   
   //--- Cache data
   MqlLogifyModel    m_cache[];
   int               m_index_cache;
   
   //--- Helper methods
   string            LogPath(void);
   string            LogFileExtensionToStr(ENUM_LOG_FILE_EXTENSION file_extension);
   bool              SearchForFilesInDirectory(string directory, string &file_names[]);
   
public:
                     CLogifyHandlerFile(void);
                    ~CLogifyHandlerFile(void);
   
   //--- Configuration management
   void              SetConfig(MqlLogifyHandleFileConfig &config);
   MqlLogifyHandleFileConfig GetConfig(void);
   
   virtual void      Emit(MqlLogifyModel &data);         // Processes a log message and sends it to the specified destination
   virtual void      Flush(void);                        // Clears or completes any pending operations
   virtual void      Close(void);                        // Closes the handler and releases any resources
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogifyHandlerFile::CLogifyHandlerFile(void)
  {
   m_name = "file";
   m_interval_watcher.SetInterval(PERIOD_D1);
   ArrayFree(m_cache);
   m_index_cache = 0;
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogifyHandlerFile::~CLogifyHandlerFile(void)
  {
   this.Close();
  }
//+------------------------------------------------------------------+
//| Generate log file path based on config                           |
//+------------------------------------------------------------------+
string CLogifyHandlerFile::LogPath(void)
  {
   string file_extension = this.LogFileExtensionToStr(m_config.file_extension);
   string base_name = m_config.base_filename + file_extension;
   
   if(m_config.rotation_mode == LOG_ROTATION_MODE_SIZE || m_config.rotation_mode == LOG_ROTATION_MODE_NONE)
     {
      return(m_config.directory + "\\" + base_name);
     }
   else if(m_config.rotation_mode == LOG_ROTATION_MODE_DATE)
     {
      MqlDateTime date;
      TimeCurrent(date);
      string date_str = IntegerToString(date.year) + "-" + IntegerToString(date.mon, 2, '0') + "-" + IntegerToString(date.day, 2, '0');
      base_name = date_str + (m_config.base_filename != "" ? "-" + m_config.base_filename : "") + file_extension;
      return(m_config.directory + "\\" + base_name);
     }
   
   //--- Default return
   return(base_name);
  }
//+------------------------------------------------------------------+
//| Convert log file extension enum to string                        |
//+------------------------------------------------------------------+
string CLogifyHandlerFile::LogFileExtensionToStr(ENUM_LOG_FILE_EXTENSION file_extension)
  {
   switch(file_extension)
     {
      case LOG_FILE_EXTENSION_LOG:
        return(".log");
      case LOG_FILE_EXTENSION_TXT:
        return(".txt");
      case LOG_FILE_EXTENSION_JSON:
        return(".json");
     }
   //--- Default return
   return(".txt");
  }
//+------------------------------------------------------------------+
//| Returns an array with the names of all files in the directory    |
//+------------------------------------------------------------------+
bool CLogifyHandlerFile::SearchForFilesInDirectory(string directory,string &file_names[])
  {
   //--- Search for all log files in the specified directory with the given file extension
   string file_name;
   long search_handle = FileFindFirst(directory,file_name);
   ArrayFree(file_names);
   bool is_found = false;
   if(search_handle != INVALID_HANDLE)
     {
      do
        {
         //--- Add each file name found to the array of file names
         int size_file = ArraySize(file_names);
         ArrayResize(file_names,size_file+1);
         file_names[size_file] = file_name;
         is_found = true;
        }
      while(FileFindNext(search_handle,file_name));
      FileFindClose(search_handle);
     }
   
   return(is_found);
  }
//+------------------------------------------------------------------+
//| Set configuration                                                |
//+------------------------------------------------------------------+
void CLogifyHandlerFile::SetConfig(MqlLogifyHandleFileConfig &config)
  {
   m_config = config;
   
   //--- Validade
   string err_msg = "";
   if(!m_config.ValidateConfig(err_msg))
     {
      Print("[ERROR] ["+TimeToString(TimeCurrent())+"] Log system error: "+err_msg);
     }
  }
//+------------------------------------------------------------------+
//| Get configuration                                                |
//+------------------------------------------------------------------+
MqlLogifyHandleFileConfig CLogifyHandlerFile::GetConfig(void)
  {
   return(m_config);
  }
//+------------------------------------------------------------------+
//| Processes a log message and sends it to the specified destination|
//+------------------------------------------------------------------+
void CLogifyHandlerFile::Emit(MqlLogifyModel &data)
  {
   //--- Checks if the configured level allows
   if(data.level >= this.GetLevel())
     {
      //--- Resize cache if necessary
      int size = ArraySize(m_cache);
      if(size != m_config.messages_per_flush)
        {
         ArrayResize(m_cache, m_config.messages_per_flush);
         size = m_config.messages_per_flush;
        }
      
      //--- Add log to cache
      m_cache[m_index_cache++] = data;
      
      //--- Flush if cache limit is reached or update condition is met
      if(m_index_cache >= m_config.messages_per_flush || m_interval_watcher.Inspect())
        {
         //--- Save cache
         Flush();
         
         //--- Reset cache
         m_index_cache = 0;
         for(int i=0;i<size;i++)
           {
            m_cache[i].Reset();
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Clears or completes any pending operations                       |
//+------------------------------------------------------------------+
void CLogifyHandlerFile::Flush(void)
  {
   //--- Get the full path of the file
   string log_path = this.LogPath();
   
   //--- Open file
   ResetLastError();
   int handle_file = FileOpen(log_path, FILE_READ|FILE_WRITE|FILE_ANSI, '\t', m_config.codepage);
   if(handle_file == INVALID_HANDLE)
     {
      Print("[ERROR] ["+TimeToString(TimeCurrent())+"] Log system error: Unable to open log file '"+log_path+"'. Ensure the directory exists and is writable. (Code: "+IntegerToString(GetLastError())+")");
      return;
     }
   
   //--- Loop through all cached messages
   int size = ArraySize(m_cache);
   for(int i=0;i<size;i++)
     {
      if(m_cache[i].timestamp > 0)
        {
         //--- Point to the end of the file and write the message
         FileSeek(handle_file, 0, SEEK_END);
         FileWrite(handle_file, m_cache[i].formated);
        }
     }
      
   //--- Size in megabytes
   ulong size_mb = FileSize(handle_file) / (1024 * 1024);
   
   //--- Close file
   FileClose(handle_file);
   
   string file_extension = this.LogFileExtensionToStr(m_config.file_extension);
   
   //--- Check if the log rotation mode is based on file size
   if(m_config.rotation_mode == LOG_ROTATION_MODE_SIZE)
     {
      //--- Check if the current file size exceeds the maximum configured size
      if(size_mb >= m_config.max_file_size_mb)
        {
         //--- Search files
         string file_names[];
         if(this.SearchForFilesInDirectory(m_config.directory+"\\*"+file_extension,file_names))
           {
            //--- Delete files exceeding the configured maximum number of log files
            int size_file = ArraySize(file_names);
            for(int i=size_file-1;i>=0;i--)
              {
               //--- Extract the numeric part of the file index
               string file_index = file_names[i];
               StringReplace(file_index,file_extension,"");
               StringReplace(file_index,m_config.base_filename,"");
               
               //--- If the file index exceeds the maximum allowed count, delete the file
               if(StringToInteger(file_index) >= m_config.max_file_count)
                 {
                  FileDelete(m_config.directory + "\\" + file_names[i]);
                 }
              }
            
            //--- Rename existing log files by incrementing their indices
            for(int i=m_config.max_file_count-1;i>=0;i--)
              {
               string old_file = m_config.directory + "\\" + m_config.base_filename + (i == 0 ? "" : StringFormat("%d", i)) + file_extension;
               string new_file = m_config.directory + "\\" + m_config.base_filename + StringFormat("%d", i + 1) + file_extension;
               if(FileIsExist(old_file))
                 {
                  FileMove(old_file, 0, new_file, FILE_REWRITE);
                 }
              }
            
            //--- Rename the primary log file to include the index "1"
            string new_primary = m_config.directory + "\\" + m_config.base_filename + "1" + file_extension;
            FileMove(log_path, 0, new_primary, FILE_REWRITE);
           }
        }
     }
   //--- Check if the log rotation mode is based on date
   else if(m_config.rotation_mode == LOG_ROTATION_MODE_DATE)
     {
      //--- Search files
      string file_names[];
      if(this.SearchForFilesInDirectory(m_config.directory+"\\*"+file_extension,file_names))
        {
         //--- Delete files exceeding the maximum configured number of log files
         int size_file = ArraySize(file_names);
         for(int i=size_file-1;i>=0;i--)
           {
            if(i < size_file - m_config.max_file_count)
              {
               FileDelete(m_config.directory + "\\" + file_names[i]);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Closes the handler and releases any resources                    |
//+------------------------------------------------------------------+
void CLogifyHandlerFile::Close(void)
  {
   //--- Save cache
   Flush();
  }
//+------------------------------------------------------------------+
