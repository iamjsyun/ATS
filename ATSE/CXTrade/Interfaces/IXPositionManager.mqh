#ifndef IXPOSITIONMANAGER_MQH
#define IXPOSITIONMANAGER_MQH

#include <Object.mqh>
#include "ICXParam.mqh"

/**
 * @class IXPositionManager
 * @brief 오픈된 포지션의 모니터링 및 관리를 위한 인터페이스
 */
class IXPositionManager : public CObject {
public:
    virtual void Pulse(ICXParam* xp) = 0;
    virtual bool ModifyPosition(ICXParam* xp, ulong ticket, double sl, double tp) = 0;
};

#endif
