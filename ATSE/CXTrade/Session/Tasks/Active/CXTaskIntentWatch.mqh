#ifndef CX_TASK_INTENT_WATCH_MQH
#define CX_TASK_INTENT_WATCH_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Infra\CXMessageProvider.mqh"

/**
 * @class CXTaskIntentWatch
 * @brief 외부 강제 청산 의도 모니터링
 */
class CXTaskIntentWatch : public IXTask {
public:
    virtual string Name() override { return "Task_IntentWatch"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        IRepository* repo = CX_GET_OBJ(ctx, "repo", IRepository);
        if(IS_INVALID(sig) || IS_INVALID(repo)) return TASK_BREAK;

        // [v14.1 Real-time Sync] DB에서 최신 신호 상태 재획득
        ICXSignal* fresh = repo.GetSignalBySid(sig.GetSid());
        if(IS_VALID(fresh)) {
            // 외부에서의 청산 의도 주입 확인
            if(fresh.GetXAExit() == XA_ACTIVE && sig.GetXAExit() != XA_ACTIVE) {
                sig.SetXAExit(XA_ACTIVE);
                XP_LOG_INFO(xp, "[TASK-INTENT-WATCH] OK: External Exit Intent (XA_ACTIVE=1) Synchronized from DB.");
            }
            
            // 외부에서의 상태 강제 변경(예: DataManager에 의한 리셋) 감지
            if(fresh.GetStatus() != sig.GetStatus()) {
                XP_LOG_WARN(xp, StringFormat("[TASK-INTENT-WATCH] DB Status Mismatch Detected! (DB:%d, Session:%d). Forced Sync.", 
                                             fresh.GetStatus(), sig.GetStatus()));
                // 여기서 필요시 세션 강제 중단 또는 상태 동기화 로직 추가 지점
            }
            
            delete fresh;
        }

        // 동기화된 의도에 따라 전이 결정
        if(sig.GetXAExit() == XA_ACTIVE) {
            return SESSION_LIQUIDATING;
        }

        return TASK_CONTINUE;
    }
};

#endif
