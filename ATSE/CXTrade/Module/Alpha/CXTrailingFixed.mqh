#ifndef CXTRAILINGFIXED_MQH
#define CXTRAILINGFIXED_MQH

#include "..\..\Interfaces\IXTrailingStrategy.mqh"
#include "..\..\Models\CXSignal.mqh"
#include "CXPriceTracker.mqh"

/**
 * @class CXTrailingFixed
 * @brief 고정 포인트(Step) 기반의 수동 트레일링 전략
 */
class CXTrailingFixed : public IXTrailingStrategy {
private:
    CXPriceTracker* m_tracker;

public:
    CXTrailingFixed() {
        m_tracker = new CXPriceTracker();
    }
    
    virtual ~CXTrailingFixed() {
        SAFE_DELETE(m_tracker);
    }

    /**
     * @brief 트레일링 계산 (DEPRECATED: 현재는 IXStep 기반 계산 스텝으로 대체 권장)
     * @details 로직은 CXStepEntryTrailingCalc / CXStepExitTrailingCalc로 분화되었습니다.
     */
    virtual double Calculate(ICXParam* xp, ICXContext* ctx) {
        return 0;
    }
};

#endif
