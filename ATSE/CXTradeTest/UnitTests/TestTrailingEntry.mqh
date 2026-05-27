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
        CXVirtualPricer pricer("EURUSD", 0.00001);
        MockPriceManager priceMgr(NULL);
        priceMgr.SetPricer(GetPointer(pricer));
        MockTerminalPlatform terminal;
        
        ctx.Register("price_mgr", GetPointer(priceMgr));
        ctx.Register("terminal_platform", GetPointer(terminal));
        
        CXParam xp;
        CXSignal sig;
        sig.SetSymbol("EURUSD");
        sig.SetDir(CX_DIR_BUY);
        sig.SetType(ORDER_LIMIT);
        sig.SetPriceOpen(1.0900);
        sig.SetPriceSignal(1.0950);
        sig.SetTEStart(10);  // 1.0950 - 10pt = 1.0940 trigger
        sig.SetTEStep(5);
        sig.SetTELimit(50);
        sig.SetSid("TEST-TE-01");
        xp.SetSignal(GetPointer(sig));
        
        CXTaskPending_L_Extreme taskExt;
        CXTaskPending_L_Improve taskImp;
        CXTaskPending_L_Rebound taskReb;
        
        // Phase 1: Activation Test
        pricer.OverridePrice(1.0945); // Not yet activated
        taskExt.Execute(GetPointer(xp), GetPointer(ctx));
        ICXParam* pActive = ctx.GetParam("TE_Active_TEST-TE-01");
        if(IS_INVALID(pActive) || pActive.GetInt() != 1) {
            Print("  [PASS] TE not activated at 1.0945.");
        } else {
            Print("  [FAIL] TE activated prematurely at 1.0945.");
            allPassed = false;
        }
        
        pricer.OverridePrice(1.0935); // Trigger reached (<= 1.0940)
        taskExt.Execute(GetPointer(xp), GetPointer(ctx));
        pActive = ctx.GetParam("TE_Active_TEST-TE-01");
        if(IS_VALID(pActive) && pActive.GetInt() == 1) {
            Print("  [PASS] TE activated at 1.0935.");
        } else {
            Print("  [FAIL] TE failed to activate at 1.0935.");
            allPassed = false;
        }
        
        // Phase 2: Improvement Test
        pricer.OverridePrice(1.0925); // New extreme
        taskExt.Execute(GetPointer(xp), GetPointer(ctx));
        taskImp.Execute(GetPointer(xp), GetPointer(ctx));
        ICXParam* pExt = ctx.GetParam("LastEntryExtremity_TEST-TE-01");
        if(IS_VALID(pExt) && MathAbs(pExt.GetDouble() - 1.0925) < 0.00001) {
            Print("  [PASS] Extreme updated to 1.0925.");
        } else {
            PrintFormat("  [FAIL] Extreme not updated. Expected 1.0925, got %.5f", IS_VALID(pExt)?pExt.GetDouble():0);
            allPassed = false;
        }
        
        // Phase 3: Rebound Entry Test
        pricer.OverridePrice(1.0931); // Rebound of 6pt (> TEStep 5)
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