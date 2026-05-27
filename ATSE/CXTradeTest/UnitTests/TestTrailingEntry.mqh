#ifndef TEST_TRAILING_ENTRY_MQH
#define TEST_TRAILING_ENTRY_MQH

#include "..\..\CXTrade\Session\Workflow\Pending\CXTaskPending_L_Extreme.mqh"
#include "..\..\CXTrade\Session\Workflow\Pending\CXTaskPending_L_Improve.mqh"
#include "..\..\CXTrade\Session\Workflow\Pending\CXTaskPending_L_Rebound.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXContext.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXParam.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXSignal.mqh"
#include "..\Mocks\MockPriceManager.mqh"
#include "..\Mocks\MockTerminalPlatform.mqh"
#include "..\Scenarios\CXVirtualPricer.mqh"

class TestTrailingEntry {
public:
    static bool Run() {
        Print("--- Running TestTrailingEntry ---");
        bool allPassed = true;
        
        CXContext ctx;
        CXVirtualPricer pricer("GOLDF#", 0.01);
        MockPriceManager priceMgr(NULL);
        priceMgr.SetPricer(GetPointer(pricer));
        MockTerminalPlatform terminal;
        
        ctx.Register("price_mgr", GetPointer(priceMgr));
        ctx.Register("terminal_platform", GetPointer(terminal));
        
        CXParam xp;
        CXSignal sig;
        sig.SetSymbol("GOLDF#");
        sig.SetDir(CX_DIR_BUY);
        sig.SetType(ORDER_LIMIT);
        sig.SetPriceOpen(2345.00);
        sig.SetPriceSignal(2350.00);
        sig.SetTEStart(300);  // 2350.00 - 300pt ($3.00) = 2347.00 trigger
        sig.SetTEStep(100);  // 100pt ($1.00) rebound
        sig.SetTELimit(500);  // 500pt ($5.00) limit
        sig.SetSid("TEST-TE-01");
        xp.SetSignal(GetPointer(sig));
        
        CXTaskPending_L_Extreme taskExt;
        CXTaskPending_L_Improve taskImp;
        CXTaskPending_L_Rebound taskReb;
        
        // Phase 1: Activation Test
        pricer.OverridePrice(2347.50); // Not yet activated (2.50 drop < 3.00)
        taskExt.Execute(GetPointer(xp), GetPointer(ctx));
        ICXParam* pActive = ctx.GetParam("TE_Active_TEST-TE-01");
        if(IS_INVALID(pActive) || pActive.GetInt() != 1) {
            Print("  [PASS] TE not activated at 2347.50.");
        } else {
            Print("  [FAIL] TE activated prematurely at 2347.50.");
            allPassed = false;
        }
        
        pricer.OverridePrice(2346.50); // Trigger reached (<= 2347.00)
        taskExt.Execute(GetPointer(xp), GetPointer(ctx));
        pActive = ctx.GetParam("TE_Active_TEST-TE-01");
        if(IS_VALID(pActive) && pActive.GetInt() == 1) {
            Print("  [PASS] TE activated at 2346.50.");
        } else {
            Print("  [FAIL] TE failed to activate at 2346.50.");
            allPassed = false;
        }
        
        // Phase 2: Improvement Test
        pricer.OverridePrice(2343.00); // New extreme
        taskExt.Execute(GetPointer(xp), GetPointer(ctx));
        taskImp.Execute(GetPointer(xp), GetPointer(ctx));
        ICXParam* pExt = ctx.GetParam("LastEntryExtremity_TEST-TE-01");
        if(IS_VALID(pExt) && MathAbs(pExt.GetDouble() - 2343.00) < 0.01) {
            Print("  [PASS] Extreme updated to 2343.00.");
        } else {
            PrintFormat("  [FAIL] Extreme not updated. Expected 2343.00, got %.2f", IS_VALID(pExt)?pExt.GetDouble():0);
            allPassed = false;
        }
        
        // Phase 3: Rebound Entry Test
        pricer.OverridePrice(2344.10); // Rebound of 1.10 (> TEStep 1.00 / 100pt)
        int res = taskReb.Execute(GetPointer(xp), GetPointer(ctx));
        if(xp.GetInt() == 10) { // Market Fallback trigger
            Print("  [PASS] Rebound detected and market entry triggered.");
        } else {
            PrintFormat("  [FAIL] Rebound not detected. xp.GetInt() = %d", xp.GetInt());
            allPassed = false;
        }

        return allPassed;
    }
};

#endif