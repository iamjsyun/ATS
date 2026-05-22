#ifndef TEST_REDIRECT_RECOVERY_MQH
#define TEST_REDIRECT_RECOVERY_MQH

#include "..\..\CXTrade\Session\Tasks\Entry\CXTaskEntry_L_Redirect.mqh"
#include "..\..\CXTrade\Models\CXContext.mqh"
#include "..\..\CXTrade\Models\CXParam.mqh"
#include "..\..\CXTrade\Models\CXSignal.mqh"

class TestRedirectRecovery {
public:
    static bool Run() {
        Print("--- Running TestRedirectRecovery ---");
        bool allPassed = true;
        
        CXContext ctx;
        CXParam xp;
        CXSignal sig;
        sig.SetXAEntry(XA_ACTIVE);
        xp.SetSignal(GetPointer(sig));
        
        CXTaskEntry_L_Redirect task;
        
        // Test Case 1: Status READY (Normal path)
        sig.SetStatus(XE_READY);
        int result = task.Execute(GetPointer(xp), GetPointer(ctx));
        if (result == TASK_CONTINUE) {
            Print("  [PASS] Status READY returns TASK_CONTINUE.");
        } else {
            PrintFormat("  [FAIL] Status READY: Expected TASK_CONTINUE(%d), got %d", TASK_CONTINUE, result);
            allPassed = false;
        }

        // Test Case 2: Status IN_TRANSIT (Recovery path)
        sig.SetStatus(XE_IN_TRANSIT);
        result = task.Execute(GetPointer(xp), GetPointer(ctx));
        if (result == STATE_ENTRY_TRANSIT) {
            Print("  [PASS] Status IN_TRANSIT returns STATE_ENTRY_TRANSIT.");
        } else {
            PrintFormat("  [FAIL] Status IN_TRANSIT: Expected STATE_ENTRY_TRANSIT(%d), got %d", STATE_ENTRY_TRANSIT, result);
            allPassed = false;
        }

        // Test Case 3: Status PENDING_PLACED (Recovery path)
        sig.SetStatus(XE_PENDING_PLACED);
        result = task.Execute(GetPointer(xp), GetPointer(ctx));
        if (result == STATE_ENTRY_TRAILING) {
            Print("  [PASS] Status PENDING_PLACED returns STATE_ENTRY_TRAILING.");
        } else {
            PrintFormat("  [FAIL] Status PENDING_PLACED: Expected STATE_ENTRY_TRAILING(%d), got %d", STATE_ENTRY_TRAILING, result);
            allPassed = false;
        }

        // Test Case 4: Status EXECUTED (Recovery path)
        sig.SetStatus(XE_EXECUTED);
        result = task.Execute(GetPointer(xp), GetPointer(ctx));
        if (result == SESSION_ACTIVE) {
            Print("  [PASS] Status EXECUTED returns SESSION_ACTIVE.");
        } else {
            PrintFormat("  [FAIL] Status EXECUTED: Expected SESSION_ACTIVE(%d), got %d", SESSION_ACTIVE, result);
            allPassed = false;
        }

        return allPassed;
    }
};

#endif
