#ifndef CX_TASK_ENTRY_L_REDIRECT_MQH
#define CX_TASK_ENTRY_L_REDIRECT_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskEntry_L_Redirect
 * @brief [Logic] 세션 상태 및 외부 의도에 따른 경로 재지정 (Redirect)
 */
class CXTaskEntry_L_Redirect : public IXTask {
public:
    virtual string Name() override { return "Entry_L_Redirect"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        // 1. [v12.7 Exit-First Priority] 청산 의도가 주입된 경우 모든 진입 로직 중단 및 청산 전이
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_WARN(xp, "[ENTRY-L] ABORT: Exit intent detected. Redirecting to LIQUIDATING.");
            return SESSION_LIQUIDATING;
        }

        // 2. 에러 상태인 경우 세션 에러로 전환
        if(sig.GetStatus() == XE_ERROR) {
            XP_LOG_ERROR(xp, "[ENTRY-L] Redirecting to ERROR (Signal in XE_ERROR state)");
            return SESSION_ERROR;
        }

        // [v11.6 Recovery] 이미 실물 처리 단계인 경우 해당 시퀀스로 점프
        if(sig.GetStatus() == XE_IN_TRANSIT) {
            XP_LOG_INFO(xp, "[ENTRY-L] Redirecting to TRANSIT (Recovery)");
            return STATE_ENTRY_TRANSIT;
        }
        
        if(sig.GetStatus() == XE_PENDING_PLACED) {
            XP_LOG_INFO(xp, "[ENTRY-L] Redirecting to PENDING (Recovery)");
            return STATE_ENTRY_TRAILING;
        }

        if(sig.GetStatus() >= XE_EXECUTED) {
            XP_LOG_INFO(xp, "[ENTRY-L] Redirecting to ACTIVE (Recovery)");
            return SESSION_ACTIVE;
        }
        
        // 3. 진입 의도가 없거나 이미 실행 완료된 경우 중단 (XA_ACTIVE 가 아니면 무시)
        if(sig.GetXAEntry() != XA_ACTIVE) {
            XP_LOG_TRACE(xp, StringFormat("[ENTRY-L] TASK_BREAK (XAEntry:%d, Status:%d)", sig.GetXAEntry(), sig.GetStatus()));
            return TASK_BREAK;
        }

        return TASK_CONTINUE;
    }
};

#endif
