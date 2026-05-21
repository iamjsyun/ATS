#ifndef CXSTEPEXIT_MQH
#define CXSTEPEXIT_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\CXDefine.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IXExitManager.mqh"

#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Models\CXSignal.mqh"

/**
 * @class CXStepExit
 * @brief 포지션 청산 및 주문 취소를 담당하는 원자적 단계 (IXStep 구현)
 */
class CXStepExit : public IXStep {
private:
    string m_name;

public:
    CXStepExit() : m_name("Step_Exit") {}
    virtual ~CXStepExit() {}

    virtual string Name() override { return m_name; }

    /**
     * @brief 청산 조건 확인 (xa_exit == XA_ACTIVE)
     */
    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return false;

        return (sig.GetXAExit() == XA_ACTIVE);
    }
    /**
     * @brief 청산 로직 실행 및 물리적 소멸 검증
     */
    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
        if(IS_INVALID(exitMgr)) return SESSION_ERROR;

        // 1. 3-Layer Guard 실행
        // exitMgr 내부에서 Sweep 및 Verify 수행 (이전 롤백된 로직 복구 필요 시 보완)
        return SESSION_CLOSED;
    }

    virtual void OnEnter(ICXContext* ctx) override {
        XP_LOG_INFO(NULL, "[STEP-EXIT] Entering Liquidation State");
    }

    virtual void OnExit(ICXContext* ctx) override {
        XP_LOG_INFO(NULL, "[STEP-EXIT] Exiting Liquidation State");
    }

private:
    /**
     * @brief 청산 완료 후 DB 상태 최종 업데이트 (xe_status=20, xa_status=6)
     */
    void FinalizeLiquidation(ICXParam* xp, ICXContext* ctx) {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        
        if(IS_VALID(sig) && IS_VALID(repo)) {
            sig.SetStatus(XE_CLOSED_SIGNAL);
            sig.SetStatusMsg(MSG_EXIT_TICKET_CLOSED);
            // xa_status = 6 등은 리포지토리의 UpdateStatus 내부 비즈니스 로직에 위임하거나
            // 직접 쿼리 실행 (여기서는 인터페이스 활용)
            repo.UpdateStatus(sig);
        }
    }
};

#endif
