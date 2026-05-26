#ifndef TEST_ENTRY_VALIDATE_MQH
#define TEST_ENTRY_VALIDATE_MQH

#include "..\..\CXTrade\Session\Workflow\Entry\CXTaskEntry_L_Validate.mqh"
#include "..\..\CXTrade\Session\CXContext.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXParam.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXSignal.mqh"
#include "..\Mocks\MockGuard.mqh"

class TestEntryValidate {
public:
    static bool Run() {
        Print("--- Running TestEntryValidate ---");
        bool allPassed = true;
        
        // 1. Setup Context & Mocks
        CXContext ctx;
        MockGuard guard;
        ctx.Register("guard", GetPointer(guard));
        
        CXParam xp;
        CXSignal sig;
        sig.SetStatus(XE_READY);
        sig.xa_entry = XA_ACTIVE;
        sig.symbol = "GOLD#";
        sig.lot = 0.1;
        xp.SetSignal(GetPointer(sig));
        
        CXTaskEntry_L_Validate task;
        
        // Test Case 1: 가드 실패 (Margin/Lot Validation Failure)
        guard.SetValidateLotReturn(false);
        int result = task.Execute(GetPointer(xp), GetPointer(ctx));
        
        if (result == TASK_BREAK) {
            Print("  [PASS] ValidateLot failure resulted in TASK_BREAK.");
        } else {
            PrintFormat("  [FAIL] Expected TASK_BREAK(%d), got %d", TASK_BREAK, result);
            allPassed = false;
        }
        
        // Test Case 2: 가드 성공 (Validation Success)
        guard.SetValidateLotReturn(true);
        result = task.Execute(GetPointer(xp), GetPointer(ctx));
        
        if (result == TASK_CONTINUE) {
            Print("  [PASS] Validation success resulted in TASK_CONTINUE.");
        } else {
            PrintFormat("  [FAIL] Expected TASK_CONTINUE(%d), got %d", TASK_CONTINUE, result);
            allPassed = false;
        }

        return allPassed;
    }
};

#endif