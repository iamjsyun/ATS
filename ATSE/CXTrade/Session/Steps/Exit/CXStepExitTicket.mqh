#ifndef CXSTEPEXITTICKET_MQH
#define CXSTEPEXITTICKET_MQH

#include "..\..\..\Interfaces\IXStep.mqh"
#include "..\..\..\Interfaces\IXExitManager.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXStepExitTicket
 * @brief Layer 1: 티켓 기반 정밀 청산을 수행하는 단계
 */
class CXStepExitTicket : public IXStep {
public:
    virtual string Name() override { return "Exit_L1_Ticket"; }

    virtual bool OnCondition(ICXParam* xp, ICXContext* ctx, int current_state) override {
        return true; 
    }

    virtual int OnProcess(ICXParam* xp, ICXContext* ctx) override {
        IXExitManager* exitMgr = CX_GET_OBJ(ctx, "exit_mgr", IXExitManager);
        ICXSignal* sig = xp.GetSignal();
        
        if(IS_VALID(exitMgr) && IS_VALID(sig)) {
            // 상태 업데이트: L1 청산 시작
            CXMessageProvider::UpdateStatus(sig, SESSION_LIQUIDATING, CXMessageProvider::GetExitLayerMsg(1, sig.GetSid()));
            
            if(exitMgr.CloseByTicket(xp, sig)) {
                return STATE_EXIT_SWEEP;
            }
        }
        return STATE_UNCHANGED;
    }

    virtual void OnEnter(ICXContext* ctx) override { XP_LOG_DEBUG(NULL, "[EXIT-L1] Attempting Ticket Close"); }
    virtual void OnExit(ICXContext* ctx) override {}
};

#endif

