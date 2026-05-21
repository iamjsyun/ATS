#ifndef ICXLOGGER_MQH
#define ICXLOGGER_MQH

#include <Object.mqh>
#include "CXDefine.mqh"
#include "ICXParam.mqh"

/**
 * @class ICXLogger
 * @brief 멀티 채널 로깅을 위한 공용 인터페이스 및 베이스 클래스
 */
class ICXLogger : public CObject {
public:
    virtual ~ICXLogger() {}
    virtual void Log(ENUM_LOG_LEVEL level, string msg) = 0;
    virtual void SetEnabled(bool enabled) = 0;
    virtual bool IsEnabled() const = 0;

    //-- Convenience methods for CXParam-based logging
    virtual void Trace(ICXParam* xp, string msg) { Dispatch(LOG_LVL_TRACE, xp, msg); }
    virtual void Info(ICXParam* xp, string msg)  { Dispatch(LOG_LVL_INFO, xp, msg); }
    virtual void Debug(ICXParam* xp, string msg) { Dispatch(LOG_LVL_DEBUG, xp, msg); }
    virtual void Warn(ICXParam* xp, string msg)  { Dispatch(LOG_LVL_WARN, xp, msg); }
    virtual void Error(ICXParam* xp, string msg) { Dispatch(LOG_LVL_ERROR, xp, msg); }
    virtual void Ok(ICXParam* xp, string msg)    { Dispatch(LOG_LVL_OK, xp, msg); }

    virtual void Dispatch(ENUM_LOG_LEVEL level, ICXParam* xp, string msg) {
        string sid_str = "";
        if(CheckPointer(xp) != POINTER_INVALID) {
            ICXSignal* sig = xp.GetSignal();
            if(CheckPointer(sig) != POINTER_INVALID) sid_str = sig.GetSid();
        }
        string prefix = (sid_str != "") ? "[" + sid_str + "] " : "";
        Log(level, prefix + msg);
    }
};

#endif
