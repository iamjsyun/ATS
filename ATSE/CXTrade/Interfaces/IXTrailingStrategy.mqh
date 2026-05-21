#ifndef IXTRAILINGSTRATEGY_MQH
#define IXTRAILINGSTRATEGY_MQH

#include <Object.mqh>
#include "ICXParam.mqh"
#include "ICXContext.mqh"

/**
 * @class IXTrailingStrategy
 * @brief 진입(Entry) 및 청산(Exit) 트레일링 공용 인터페이스
 */
class IXTrailingStrategy : public CObject {
public:
    virtual ~IXTrailingStrategy() {}
    
    /**
     * @brief 트레일링 로직 실행 및 갱신 가격 계산
     * @return 갱신된 목표 가격 (0일 경우 변경 없음, -1일 경우 중단/취소)
     */
    virtual double Calculate(ICXParam* xp, ICXContext* ctx) = 0;
    
    /**
     * @brief 현재 트레일링 타겟 가격 조회
     */
    virtual double TargetPrice() const = 0;
    
    virtual void   Reset() = 0;
    virtual string Name() const = 0;
};

#endif
