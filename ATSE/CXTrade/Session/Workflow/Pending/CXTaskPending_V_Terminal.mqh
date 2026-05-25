#ifndef CX_TASK_PENDING_V_TERMINAL_MQH
#define CX_TASK_PENDING_V_TERMINAL_MQH

#include "..\..\..\Core\Interfaces\IXTask.mqh"
#include "..\..\..\Core\Macros\CXMacros.mqh"
#include "..\..\..\Core\Interfaces\ICXInventoryManager.mqh"
#include "..\..\..\Shared\Logging\CXAuditFormatter.mqh"

/**
 * @class CXTaskPending_V_Terminal
 * @brief [Verify] 터미널 내 대기 오더 존재 여부 검증 (v17.6)
 */
class CXTaskPending_V_Terminal : public IXTask {
public:
    virtual string Name() override { return "Pending_V_Terminal"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(sig) || IS_INVALID(invMgr)) return TASK_BREAK;

        ulong ticket = (ulong)sig.GetTicket();
        if(ticket <= 0) return TASK_BREAK;

        // 터미널에 오더가 존재하는지 확인
        bool exists = invMgr.IsOrderExists(ticket);
        
        if(exists) {
            XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-V-TERM", xp, StringFormat("OK: Order %I64u found in Terminal.", ticket)));
            return TASK_CONTINUE;
        }

        // 지연 가능성을 고려하여 Yield (Watcher에서 Retry 처리됨)
        XP_LOG_WARN(xp, CXAuditFormatter::Build("PEND-V-TERM", xp, StringFormat("WAIT: Order %I64u not yet visible in Terminal.", ticket)));
        return TASK_YIELD;
    }
};

#endif
