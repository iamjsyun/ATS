#ifndef CX_TASK_ENTRY_V_REAL_MQH
#define CX_TASK_ENTRY_V_REAL_MQH

#include "..\..\..\Interfaces\IXTask.mqh"
#include "..\..\..\Interfaces\ICXInventoryManager.mqh"
#include "..\..\..\Interfaces\CXMacros.mqh"

/**
 * @class CXTaskEntry_V_Real
 * @brief [Verify] 터미널 내 실물 자산(Position/Order) 존재 확인 및 데이터 동기화
 */
class CXTaskEntry_V_Real : public IXTask {
public:
    virtual string Name() override { return "Entry_V_Real"; }
    virtual int Execute(ICXParam* xp, ICXContext* ctx) override {
        ICXSignal* sig = xp.GetSignal();
        ICXInventoryManager* invMgr = CX_GET_OBJ(ctx, "inventory_mgr", ICXInventoryManager);
        
        if(IS_INVALID(sig) || IS_INVALID(invMgr)) {
            XP_LOG_ERROR(xp, "[ENTRY-V-REAL] FAILED: Required services missing.");
            return TASK_BREAK;
        }

        ulong ticket = (ulong)sig.GetTicket();
        string assetType = (sig.GetType() == ORDER_MARKET) ? "Position" : "Order";

        XP_LOG_TRACE(xp, StringFormat("[ENTRY-V-REAL] Verifying Real Asset: %s(%I64u)...", assetType, ticket));

        // InventoryManager를 통한 실물 존재 확인 (SSOC)
        if(!invMgr.IsAssetExists(ticket, sig.GetType())) {
            if(IsTimedOut()) {
                XP_LOG_ERROR(xp, StringFormat("[ENTRY-V-REAL] FAILED: %s(%I64u) Verification Timeout.", assetType, ticket));
                return SESSION_ERROR;
            }
            return TASK_YIELD;
        }

        // 실물 데이터 동기화 (Shadowing)
        invMgr.SyncToSignal(sig);
        XP_LOG_OK(xp, StringFormat("[ENTRY-V-REAL] SUCCESS: %s(%I64u) Confirmed and Synced.", assetType, ticket));

        return STATE_ENTRY_VERIFY;
    }
};

#endif
