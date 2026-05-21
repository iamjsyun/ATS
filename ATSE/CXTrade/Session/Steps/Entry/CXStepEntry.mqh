#ifndef CXSTEPENTRY_MQH
#define CXSTEPENTRY_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\CXDefine.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXOrderManager.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXStepEntry
 * @brief 신규 주문 진입에 해당하는 원자적 단계 (IXStep 구현)
 */
class CXStepEntry : public IXStep {
private:
    string m_name;

public:
    CXStepEntry() : m_name("Step_Entry") {}
    virtual ~CXStepEntry() {}

    virtual string Name() override { return m_name; }

    /**
     * @brief 진입 조건 확인 (xa_entry == XA_ACTIVE AND xe_status < XE_EXECUTED)
     */
    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return false;

        // spec.md: Entry activation (xa_entry == XA_ACTIVE AND xe_status < XE_EXECUTED)
        // xa_status 제거에 따라 Intent(xa_entry) 존재 여부만으로 즉시 진입 시도
        return (sig.GetXAEntry() == XA_ACTIVE &&
                sig.GetStatus() < XE_EXECUTED);
    }
    /**
     * @brief 진입 로직 실행
     */
    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        XP_LOG_INFO(xp, "[STEP-ENTRY] Executing Market/Trailing Entry...");
        
        IXOrderManager* orderMgr = CX_GET_OBJ(ctx, "order_mgr", IXOrderManager);
        if(IS_VALID(orderMgr)) {
            if(orderMgr.ExecuteEntry(xp)) {
                ICXSignal* sig = xp.GetSignal();
                if(IS_VALID(sig) && sig.GetType() == ORDER_MARKET) {
                    return SESSION_ACTIVE;
                }
                return STATE_ENTRY_TRAILING;
            }
        }

        XP_LOG_ERROR(xp, "[STEP-ENTRY] Entry execution failed. Transitioning to SESSION_ERROR.");
        return SESSION_ERROR; // 실패 시 에러 상태로 전이하여 좀비 세션 방지
    }

    virtual void OnEnter(ICXContext* ctx) override {
        XP_LOG_DEBUG(NULL, "[STEP-ENTRY] Entering Entry State");
    }

    virtual void OnExit(ICXContext* ctx) override {
        XP_LOG_DEBUG(NULL, "[STEP-ENTRY] Exiting Entry State");
    }
};

#endif



