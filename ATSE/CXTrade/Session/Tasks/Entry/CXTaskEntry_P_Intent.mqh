#ifndef CX_TASK_ENTRY_P_INTENT_MQH
#define CX_TASK_ENTRY_P_INTENT_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Interfaces\IRepository.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskEntry_P_Intent
 * @brief [Persistence] 계산된 가격 정보 및 XE_PENDING_REQ 상태를 DB에 저장
 */
class CXTaskEntry_P_Intent : public IXTask {
public:
    virtual string Name() override { return "Entry_P_Intent"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(repo)) return TASK_BREAK;

        if(sig.GetStatus() >= XE_PENDING_REQ) {
            XP_LOG_TRACE(xp, "[ENTRY-P] SKIP: Intent already persisted.");
            return TASK_CONTINUE;
        }

        XP_LOG_TRACE(xp, "[ENTRY-P] Persisting Entry Intent (Status: PENDING_REQ) to DB...");
        
        // 1. 상태 업데이트
        CXMessageProvider::UpdateStatus(sig, XE_PENDING_REQ, "Intent: Physical Order Requesting...");
        
        // 2. 전체 데이터 저장 (계산된 가격 정보 포함)
        repo.SaveSignal(sig);
        
        XP_LOG_OK(xp, "[ENTRY-P] SUCCESS: Entry Intent Persisted.");

        return TASK_CONTINUE;
    }
};

#endif
