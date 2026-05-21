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

        // 1. 청산 의도 감지 시 즉시 청산 파이프라인으로 이동
        if(sig.GetXAExit() == XA_ACTIVE) {
            XP_LOG_INFO(xp, "[ENTRY-L] Redirecting to LIQUIDATING (Exit Intent Detected)");
            return SESSION_LIQUIDATING;
        }

        // 2. 에러 상태인 경우 세션 에러로 전환
        if(sig.GetStatus() == XE_ERROR) {
            XP_LOG_ERROR(xp, "[ENTRY-L] Redirecting to ERROR (Signal in XE_ERROR state)");
            return SESSION_ERROR;
        }
        
        // 3. 진입 의도가 없거나 이미 실행 완료된 경우 중단
        if(sig.GetXAEntry() != XA_ACTIVE || sig.GetStatus() >= XE_EXECUTED) {
            XP_LOG_TRACE(xp, StringFormat("[ENTRY-L] TASK_BREAK (XAEntry:%d, Status:%d)", sig.GetXAEntry(), sig.GetStatus()));
            return TASK_BREAK;
        }

        return TASK_CONTINUE;
    }
};

#endif
