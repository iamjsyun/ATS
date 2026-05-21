#ifndef CXCONFIG_MQH
#define CXCONFIG_MQH

#include "..\Interfaces\ICXConfig.mqh"
#include <Arrays\ArrayLong.mqh>

class CXConfig : public ICXConfig {
private:
    string         m_targetMagics;
    CArrayLong     m_magicList;
    double         m_timerInterval;
    string         m_remoteHost;
    int            m_remotePort;
    
    // Database (v10.11)
    string         m_dbName;
    bool           m_dbCommon;

    // Logging Options (Global)
    bool           m_uiLogEnabled;
    bool           m_remoteLogEnabled;
    ENUM_LOG_LEVEL m_logLevel;
    string         m_filterCnos;
    CArrayLong     m_filterCnoList;

    // Category Controls (Pair/Triplet)
    bool           m_watcher_useFile;
    bool           m_watcher_useRemote;
    bool           m_watcher_init;

    bool           m_system_useFile;
    bool           m_system_useRemote;
    bool           m_system_init;

    bool           m_session_useFile;
    bool           m_session_useRemote;
    bool           m_session_useUI;
    bool           m_session_init;

    void ParseMagics(string csv, CArrayLong &list) {
        list.Clear();
        string parts[];
        int count = StringSplit(csv, ',', parts);
        for(int i=0; i<count; i++) {
            string trim = parts[i];
            StringTrimLeft(trim);
            StringTrimRight(trim);
            if(trim != "") list.Add(StringToInteger(trim));
        }
    }

    void ParseRemoteAddr(string addr) {
        m_remoteHost = "127.0.0.1";
        m_remotePort = 878;
        string parts[];
        if(StringSplit(addr, ':', parts) == 2) {
            m_remoteHost = parts[0];
            m_remotePort = (int)StringToInteger(parts[1]);
        }
    }

public:
    CXConfig(string magics, double timer_sec, string remote_addr, 
             bool ui_log, bool remote_log, string filter_cnos,
             ENUM_LOG_LEVEL log_level,
             bool w_file, bool w_remote, bool w_init,
             bool sys_file, bool sys_remote, bool sys_init,
             bool sess_file, bool sess_remote, bool sess_ui, bool sess_init,
             string db_name = "ATS.db", bool db_common = true) {
        m_targetMagics = magics;
        m_timerInterval = timer_sec;
        m_uiLogEnabled = ui_log;
        m_remoteLogEnabled = remote_log;
        m_filterCnos = filter_cnos;
        m_logLevel = log_level;

        m_watcher_useFile = w_file;
        m_watcher_useRemote = w_remote;
        m_watcher_init = w_init;
        
        m_system_useFile = sys_file;
        m_system_useRemote = sys_remote;
        m_system_init = sys_init;
        
        m_session_useFile = sess_file;
        m_session_useRemote = sess_remote;
        m_session_useUI = sess_ui;
        m_session_init = sess_init;

        m_dbName = db_name;
        m_dbCommon = db_common;

        ParseMagics(magics, m_magicList);
        ParseMagics(filter_cnos, m_filterCnoList);
        ParseRemoteAddr(remote_addr);
    }
    
    virtual ~CXConfig() {}

    // ICXConfig Implementation
    virtual ENUM_LOG_LEVEL GetLogLevel() const override { return m_logLevel; }
    virtual string GetTargetMagics() const override { return m_targetMagics; }
    
    virtual bool IsTargetMagic(long magic) const override {
        for(int i=0; i<m_magicList.Total(); i++) {
            if(m_magicList.At(i) == magic) return true;
        }
        return false;
    }

    virtual double GetTimerInterval() const override { return m_timerInterval; }
    virtual string GetRemoteLogHost() const override { return m_remoteHost; }
    virtual int    GetRemoteLogPort() const override { return m_remotePort; }

    virtual bool IsUILogEnabled() const override { return m_uiLogEnabled; }
    virtual bool IsRemoteLogEnabled() const override { return m_remoteLogEnabled; }
    virtual bool IsBootLogEnabled() const override { return true; } 
    virtual bool IsWatcherRemoteLogEnabled() const override { return m_watcher_useRemote; }
    virtual bool IsSystemLogEnabled() const override { return m_system_useFile; }
    virtual bool IsSequenceLogEnabled(long cno) const override { return IsCnoLogEnabled(cno); }

    // Granular Control
    virtual bool IsFileLogEnabled(string cat) const override {
        if(cat == "Watcher") return m_watcher_useFile;
        if(cat == "System")  return m_system_useFile;
        if(cat == "Session") return m_session_useFile;
        return true;
    }
    virtual bool IsRemoteLogEnabled(string cat) const override {
        if(!m_remoteLogEnabled) return false;
        if(cat == "Watcher") return m_watcher_useRemote;
        if(cat == "System")  return m_system_useRemote;
        if(cat == "Session") return m_session_useRemote;
        return true;
    }
    virtual bool IsUILogEnabled(string cat) const override {
        if(!m_uiLogEnabled) return false;
        if(cat == "Session") return m_session_useUI;
        return true;
    }
    virtual bool IsCnoLogEnabled(long cno) const override {
        if(m_filterCnos == "*" || m_filterCnos == "") return true;
        for(int i=0; i<m_filterCnoList.Total(); i++) {
            if(m_filterCnoList.At(i) == cno) return true;
        }
        return false;
    }
    virtual bool IsLogInitOnStart(string cat) const override {
        if(cat == "Watcher") return m_watcher_init;
        if(cat == "System")  return m_system_init;
        if(cat == "Session") return m_session_init;
        return true;
    }

    // Database Configuration
    virtual string GetDatabaseName() const override { return m_dbName; }
    virtual bool   IsDatabaseCommon() const override { return m_dbCommon; }
};

#endif
