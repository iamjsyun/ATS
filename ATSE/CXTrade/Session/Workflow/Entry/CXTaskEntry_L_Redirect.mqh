#ifndef CX_TASK_ENTRY_L_REDIRECT_MQH
#define CX_TASK_ENTRY_L_REDIRECT_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

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

        // 1. [v12.7 Exit-First Priority] 청산 의도가 주입된 경우
        if(sig.GetXAExit() == XA_ACTIVE) {
            if(sig.GetTicket() > 0) {
                XP_LOG_WARN(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, "ABORT: Exit intent detected. Redirecting to LIQUIDATING."));
                return SESSION_LIQUIDATING;
            } else {
                string abortMsg = "ABORT: Exit intent received before order placement (Ticket=0).";
                XP_LOG_ERROR(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, abortMsg));
                if(IS_VALID(xp)) xp.SetString("[ENTRY-L-REDIR] " + abortMsg);
                return SESSION_ERROR;
            }
        }

        // 2. 에러 상태인 경우 세션 에러로 전환
        if(sig.GetStatus() == XE_ERROR) {
            string err = StringFormat("Signal SID:%s is in XE_ERROR state", sig.GetSid());
            XP_LOG_ERROR(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, "ERROR: " + err));
            if(IS_VALID(xp)) xp.SetString("[ENTRY-L-REDIR] " + err);
            return SESSION_ERROR;
        }

        // [v11.6 Recovery] 이미 실물 처리 단계인 경우 해당 시퀀스로 점프
        if(sig.GetStatus() == XE_IN_TRANSIT) {
            XP_LOG_INFO(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, "Redirecting to TRANSIT (Recovery)"));
            return STATE_ENTRY_TRANSIT;
        }
        
        if(sig.GetStatus() == XE_PENDING_PLACED) {
            XP_LOG_INFO(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, "Redirecting to PENDING (Recovery)"));
            return STATE_ENTRY_TRAILING;
        }

        if(sig.GetStatus() >= XE_EXECUTED) {
            XP_LOG_INFO(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, "Redirecting to ACTIVE (Recovery)"));
            return SESSION_ACTIVE;
        }
        
        // 3. 진입 의도가 없거나 이미 실행 완료된 경우 중단 (XA_ACTIVE 가 아니면 무시)
        if(sig.GetXAEntry() != XA_ACTIVE) {
            XP_LOG_TRACE(xp, CXAuditFormatter::Build("ENTRY-L-REDIR", xp, "XA_ENTRY not ACTIVE. Breaking."));
            return TASK_BREAK;
        }

        return TASK_CONTINUE;
    }
};

#endif
