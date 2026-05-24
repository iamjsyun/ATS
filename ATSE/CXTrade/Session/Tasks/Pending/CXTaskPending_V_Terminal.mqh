#ifndef CX_TASK_PENDING_V_TERMINAL_MQH
#define CX_TASK_PENDING_V_TERMINAL_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"
#include "..\..\..\Infra\CXAuditFormatter.mqh"

/**
 * @class CXTaskPending_V_Terminal
 * @brief [Verify] 대기 주문 실물 상태 확인 (수동 삭제 대응)
 */
class CXTaskPending_V_Terminal : public IXTask {
public:
    virtual string Name() override { return "Pending_V_Terminal"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(sig) || IS_INVALID(invMgr)) return TASK_BREAK;

        ulong ticket = (ulong)sig.GetTicket();
        bool exists = invMgr.IsOrderExists(ticket);

        XP_LOG_TRACE(xp, CXAuditFormatter::Build("PEND-V-TERM", xp, StringFormat("Checking Order:%I64u, Found:%d", ticket, exists)));
        xp.SetInt(exists ? 1 : 0); 
        return TASK_CONTINUE;
    }
};

#endif
