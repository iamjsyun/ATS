#ifndef CX_TASK_FINALIZE_V_DOUBLECHECK_MQH
#define CX_TASK_FINALIZE_V_DOUBLECHECK_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskFinalize_V_DoubleCheck
 * @brief [Verify] DB 최종 기록 전 터미널 티켓 교차 검증
 */
class CXTaskFinalize_V_DoubleCheck : public IXTask {
public:
    virtual string Name() override { return "Finalize_V_DoubleCheck"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        if(IS_INVALID(sig)) return TASK_BREAK;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) return TASK_BREAK;

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("FINAL-V-CHECK", xp, StringFormat("Double-Checking Ticket:%I64u", ticket)));

        // 최종 확정 전 실물 티켓과 매칭되는지 최종 확인
        if(!PositionSelectByTicket(ticket) && !OrderSelect(ticket)) {
            XP_LOG_ERROR(xp, CXAuditFormatter::Build("FINAL-V-CHECK", xp, StringFormat("FAILED: Phantom Ticket:%I64u", ticket)));
            return TASK_BREAK;
        }

        XP_LOG_OK(xp, CXAuditFormatter::Build("FINAL-V-CHECK", xp, "SUCCESS: Ticket verified."));
        return TASK_CONTINUE;
    }
};

#endif
