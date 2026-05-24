#ifndef CXFILELOGGER_MQH
#define CXFILELOGGER_MQH

#include "..\..\Core\Interfaces\ICXLogger.mqh"

/**
 * @class CXFileLogger
 * @brief 세션별 독립 로그 파일 생성 및 기록 담당
 */
class CXFileLogger : public ICXLogger {
private:
    int    m_handle;
    string m_filename;
    string m_sid;
    int    m_lastHour;
    bool   m_enabled;

public:
    CXFileLogger() : m_handle(INVALID_HANDLE), m_lastHour(-1), m_enabled(true) {}
    ~CXFileLogger() { Close(); }

    /**
     * @brief {sid}-{yymmdd-HH}.log 형식으로 파일 초기화 (시간 단위 생성)
     */
    bool Init(string sid) {
        m_sid = sid;
        MqlDateTime dt;
        TimeCurrent(dt);
        m_lastHour = dt.hour;

        return OpenByTime(dt);
    }

    virtual void Log(ENUM_LOG_LEVEL level, string msg) override {
        if(!m_enabled) return;

        //-- 시간 변경 감지 시 파일 재연결 (Hourly Rotation)
        MqlDateTime dt;
        TimeCurrent(dt);
        if(dt.hour != m_lastHour) {
            m_lastHour = dt.hour;
            OpenByTime(dt);
        }

        if(m_handle == INVALID_HANDLE) return;

        // [v14.44] Using Unicode for consistent multilingual support
        string line = StringFormat("[%s] [%s] %s\r\n", EnumToString(level), TimeToString(TimeCurrent(), TIME_SECONDS), msg);
        FileWriteString(m_handle, line);
        FileFlush(m_handle);
    }

private:
    bool OpenByTime(MqlDateTime &dt) {
        Close();

        //-- [v14.42] Ensure directory exists
        if(!FolderCreate("ATSE", FILE_COMMON)) {
            int err = GetLastError();
            if(err != 0 && err != 5019) { // 5019: Folder already exists
                PrintFormat("[LOG-ERR] FolderCreate ATSE failed. Code:%d", err);
            }
        }

        //-- [v10.18] Format Update: {yyMMdd-HH0000}.log
        string timestamp = StringFormat("%02d%02d%02d-%02d0000", 
            dt.year % 100, dt.mon, dt.day, dt.hour);

        m_filename = StringFormat("ATSE\\%s-%s.log", m_sid, timestamp);
        
        //-- [v14.44 Robust Open] 
        // 1. First attempt: Open for Read/Write (Append mode)
        int flags = FILE_TXT|FILE_SHARE_READ|FILE_UNICODE|FILE_COMMON|FILE_READ|FILE_WRITE;
        m_handle = FileOpen(m_filename, flags);

        // 2. Second attempt: Create new if not exists
        if(m_handle == INVALID_HANDLE) {
            flags = FILE_TXT|FILE_SHARE_READ|FILE_UNICODE|FILE_COMMON|FILE_WRITE;
            m_handle = FileOpen(m_filename, flags);
        }

        if(m_handle != INVALID_HANDLE) {
            FileSeek(m_handle, 0, SEEK_END);
            return true;
        }
        
        //-- [v14.44] Replace MessageBox with Print for Tester/Headless compatibility
        PrintFormat("[LOG-CRITICAL] Failed to create log file! Path: ATSE\\%s, SID: %s, Error Code: %d", 
                    m_filename, m_sid, GetLastError());
        
        return false;
    }

public:
    virtual void SetEnabled(bool enabled) override { m_enabled = enabled; }
    virtual bool IsEnabled() const override { return m_enabled; }

    void Close() {
        if(m_handle != INVALID_HANDLE) {
            FileClose(m_handle);
            m_handle = INVALID_HANDLE;
        }
    }
};

#endif
