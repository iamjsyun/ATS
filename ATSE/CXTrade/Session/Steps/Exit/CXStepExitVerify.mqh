#ifndef CXSTEPEXITVERIFY_MQH
#define CXSTEPEXITVERIFY_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXExitManager.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXStepExitVerify
 * @brief Layer 3: 자산의 물리적 존재 여부를 최종 확인하는 단계
 */
class CXStepExitVerify : public IXStep {
private:
    int m_failCount;

public:
    CXStepExitVerify() : m_failCount(0) {}
    virtual string Name() override { return "Exit_L3_Verify"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true;
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        
        if(IS_VALID(exitMgr) && IS_VALID(sig)) {
            CXMessageProvider::UpdateStatus(sig, SESSION_LIQUIDATING, CXMessageProvider::GetExitLayerMsg(3, sig.GetSid()));

            if(exitMgr.VerifyPhysicalAbsence(sig.GetSid())) {
                m_failCount = 0; // 리셋
                CXMessageProvider::UpdateStatus(sig, XE_CLOSED_SIGNAL, MSG_EXIT_VERIFIED_CLEAN);
                
                if(IS_VALID(repo)) repo.UpdateStatus(sig);
                
                return SESSION_CLOSED; 
            } else {
                m_failCount++;
                XP_LOG_WARN(xp, StringFormat("[EXIT-L3] Verification Failed! Count:%d", m_failCount));
                if(m_failCount >= 3) {
                    XP_LOG_ERROR(xp, "[EXIT-L3] Circuit Breaker Tripped! Emergency Error.");
                    return SESSION_ERROR;
                }
            }
        }
        return SESSION_LIQUIDATING;
    }

    virtual void OnEnter(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[EXIT-L3] Verifying asset absence"); }
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif

