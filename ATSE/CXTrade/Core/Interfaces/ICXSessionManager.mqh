#ifndef ICXSESSIONMANAGER_MQH
#define ICXSESSIONMANAGER_MQH

#include <Object.mqh>
#include "IRepository.mqh"
#include "ICXContext.mqh"
#include "ICXParam.mqh"
#include "ICXServiceFactory.mqh"
#include "ICXTradingSession.mqh"

/**
 * @class ICXSessionManager
 * @brief 트레이딩 세션의 동적 생성, 검색 및 생명주기 관리 인터페이스 (v14.47)
 */
class ICXSessionManager : public CObject {
public:
    virtual ~ICXSessionManager() {}
    
    virtual void              Initialize(IRepository* repo, ICXContext* ctx, ICXServiceFactory* factory) = 0;
    virtual void              Pulse(ICXParam* xp) = 0;
    
    // [v15.9] Create new session instance with signal context
    virtual ICXTradingSession* CreateSession(ICXParam* xp) = 0;
    virtual ICXTradingSession* FindSessionBySid(const string sid) = 0;
};

#endif
