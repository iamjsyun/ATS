#ifndef CXSTEPEXITSWEEP_MQH
#define CXSTEPEXITSWEEP_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXExitManager.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXStepExitSweep
 * @brief Layer 2: SID 코멘트 기반 강제 소멸(스윕)을 수행하는 단계
 */
class CXStepExitSweep : public IXStep {
public:
    virtual string Name() override { return "Exit_L2_Sweep"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true;
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
        ICXSignal* sig = xp.GetSignal();
        
        if(IS_VALID(exitMgr) && IS_VALID(sig)) {
            // 상태 업데이트: L2 스윕 시작
            CXMessageProvider::UpdateStatus(sig, SESSION_LIQUIDATING, CXMessageProvider::GetExitLayerMsg(2, sig.GetSid()));

            if(exitMgr.SweepBySid(xp, sig.GetSid())) {
                return STATE_EXIT_VERIFY;
            }
        }
        return STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[EXIT-L2] Sweeping by SID comment"); }
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif

