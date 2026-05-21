#ifndef CXFILELOGGER_MQH
#define CXFILELOGGER_MQH

#include "..\Interfaces\ICXLogger.mqh"

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
    bool   m_initOnStart;

public:
    CXFileLogger() : m_handle(INVALID_HANDLE), m_lastHour(-1), m_enabled(true), m_initOnStart(true) {}
    ~CXFileLogger() { Close(); }

    /**
     * @brief {sid}-{yymmdd-HH}.log 형식으로 파일 초기화 (시간 단위 생성)
     */
    bool Init(string sid, bool initOnStart = true) {
        m_sid = sid;
        m_initOnStart = initOnStart;
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
            m_initOnStart = false; //-- Rotation 시에는 항상 Append
            OpenByTime(dt);
        }

        if(m_handle == INVALID_HANDLE) return;

        string line = StringFormat("[%s] [%s] %s\n", EnumToString(level), TimeToString(TimeCurrent(), TIME_SECONDS), msg);
        FileWriteString(m_handle, line);
        FileFlush(m_handle);
    }

private:
    bool OpenByTime(MqlDateTime &dt) {
        Close();

        //-- [v10.18] Format Update: {yyMMdd-HH0000}.log
        string timestamp = StringFormat("%02d%02d%02d-%02d0000", 
            dt.year % 100, dt.mon, dt.day, dt.hour);

        m_filename = StringFormat("ATSE\\%s-%s.log", m_sid, timestamp);
        
        //-- [v10.5] Fix Clear Logic: FILE_WRITE without FILE_READ truncates the file.
        int baseFlags = FILE_TXT|FILE_SHARE_READ|FILE_ANSI|FILE_COMMON;
        
        if(m_initOnStart) {
            //-- Overwrite (Truncate) mode
            m_handle = FileOpen(m_filename, baseFlags | FILE_WRITE);
            m_initOnStart = false; //-- Subsequent opens (rotation) will be Append
        } else {
            //-- Append mode (Maintain existing content)
            m_handle = FileOpen(m_filename, baseFlags | FILE_READ | FILE_WRITE);
        }

        if(m_handle != INVALID_HANDLE) {
            FileSeek(m_handle, 0, SEEK_END);
            return true;
        }
        
        //-- [v10.1] File Creation Error Alert
        string errorMsg = StringFormat("CRITICAL: Failed to create log file!\nPath: MQL5\\Files\\Common\\%s\nSID: %s\nError Code: %d", 
                                       m_filename, m_sid, GetLastError());
        MessageBox(errorMsg, "ATSE Log Engine Error", MB_OK|MB_ICONHAND);
        
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
