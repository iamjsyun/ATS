#ifndef ICXTRADINGSESSION_MQH
#define ICXTRADINGSESSION_MQH

#include <Object.mqh>
#include "ICXParam.mqh"
#include "ICXServiceFactory.mqh"

/**
 * @class ICXTradingSession
 * @brief 독립적인 샌드박스 실행 단위에 대한 추상 인터페이스
 */
class ICXTradingSession : public CObject {
public:
    virtual ~ICXTradingSession() {}

    virtual void Pulse(ICXParam* xp) = 0;
    virtual void Start(ICXParam* xp) = 0;
    virtual void InjectState(CXSignal* sig) = 0;
    virtual void ForceTransition(int state) = 0;
    virtual bool IsActive() const = 0;
    virtual string GetSid() const = 0;
    virtual ICXSignal* GetSignal() const = 0;
    virtual int        GetState() const = 0;
};

#endif
