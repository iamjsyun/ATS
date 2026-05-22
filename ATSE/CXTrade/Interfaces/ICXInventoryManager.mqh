#ifndef ICXINVENTORYMANAGER_MQH
#define ICXINVENTORYMANAGER_MQH

#include <Object.mqh>
#include "ICXSignal.mqh"

/**
 * @interface ICXInventoryManager
 * @brief 터미널 실물 자산(Position/Order) 상태 관리 전문 인터페이스 (SSOC: Inventory)
 */
class ICXInventoryManager : public CObject {
public:
    virtual ~ICXInventoryManager() {}

    //-- 실물 존재 여부 확인
    virtual bool IsPositionExists(ulong ticket) = 0;
    virtual bool IsOrderExists(ulong ticket) = 0;
    virtual bool IsAssetExists(ulong ticket, int type) = 0; // ORDER_MARKET -> Position, Else -> Order

    //-- 실물 데이터 동기화 (Shadowing)
    virtual bool SyncToSignal(ICXSignal* sig) = 0;
    
    //-- 속성 추출
    virtual double GetCurrentVolume(ulong ticket, bool isPosition) = 0;
    virtual double GetCurrentPriceOpen(ulong ticket, bool isPosition) = 0;
    virtual double GetCurrentSL(ulong ticket) = 0;
    virtual double GetCurrentTP(ulong ticket) = 0;
    virtual double GetCurrentProfit(ulong ticket) = 0;

    //-- 히스토리 추적
    virtual int    CheckHistoryClosure(ulong ticket, string &reason) = 0;

    // [v13.4 UAF Standard]
    virtual string GetAuditString(ICXParam* xp, string actionLabel = "") = 0;
};

#endif
