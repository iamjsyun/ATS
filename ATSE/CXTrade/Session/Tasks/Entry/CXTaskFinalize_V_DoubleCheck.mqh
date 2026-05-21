#ifndef CX_TASK_FINALIZE_V_DOUBLECHECK_MQH
#define CX_TASK_FINALIZE_V_DOUBLECHECK_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

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

        XP_LOG_TRACE(xp, StringFormat("[FINAL-V-CHECK] Performing Double-Check for Physical Ticket:%I64u...", ticket));

        // 최종 확정 전 실물 티켓과 매칭되는지 최종 확인
        if(!PositionSelectByTicket(ticket) && !OrderSelect(ticket)) {
            XP_LOG_ERROR(xp, StringFormat("[FINAL-V-CHECK] FAILED: Phantom Ticket Detected (%I64u). Ticket is not found in terminal.", ticket));
            return TASK_BREAK;
        }

        XP_LOG_OK(xp, "[FINAL-V-CHECK] SUCCESS: Ticket verified in terminal. Finalizing...");
        return TASK_CONTINUE;
    }
};

#endif
