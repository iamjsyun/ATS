#ifndef CX_TASK_ACTIVE_V_TERMINAL_MQH
#define CX_TASK_ACTIVE_V_TERMINAL_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskActive_V_Terminal
 * @brief [Verify] 터미널 실물 상태 확인 (SL/TP 히트 여부 등)
 */
class CXTaskActive_V_Terminal : public IXTask {
public:
    virtual string Name() override { return "Active_V_Terminal"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(sig) || IS_INVALID(invMgr)) return TASK_BREAK;

        ulong ticket = (ulong)sig.GetTicket();
        bool exists = invMgr.IsPositionExists(ticket);

        XP_LOG_TRACE(xp, StringFormat("[ACTIVE-V-TERMINAL] Checking Position:%I64u, Found:%d", ticket, exists));
        xp.SetInt(exists ? 1 : 0); 
        return TASK_CONTINUE;
    }
};

#endif
