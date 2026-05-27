#ifndef TEST_TRAILING_STOP_MQH
#define TEST_TRAILING_STOP_MQH

#include "..\..\CXTrade\Session\Workflow\Active\CXTaskAlphaCalc.mqh"
#include "..\..\CXTrade\Session\Workflow\Active\CXTaskAlphaApply.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXContext.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXParam.mqh"
#include "..\..\CXTrade\Platform\Core\Models\CXSignal.mqh"
#include "..\Mocks\MockPriceManager.mqh"
#include "..\Mocks\MockTerminalPlatform.mqh"
#include "..\Scenarios\CXVirtualPricer.mqh"

class TestTrailingStop {
public:
    static bool Run() {
        Print("--- Running TestTrailingStop ---");
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
        sig.SetType(ORDER_TYPE_BUY);
        sig.SetPriceOpen(2350.00);
        sig.SetTSStart(2000); // TS Start at +2000pt ($20.00)
        sig.SetTSStep(500);   // TS Step 500pt ($5.00)
        sig.SetTicket(90001);
        sig.SetSid("TEST-TS-01");
        xp.SetSignal(GetPointer(sig));
        
        // Inject physical position
        terminal.InjectMockAsset(true, 90001, "TEST-TS-01", "GOLDF#", 1001, CX_DIR_BUY, 0.1, 2350.00, 0, 0);
        
        CXTaskAlphaCalc taskCalc;
        CXTaskAlphaApply taskApply;
        
        // 1. Below trigger
        pricer.OverridePrice(2360.00); // +10.00 profit < +20.00 trigger
        taskCalc.Execute(GetPointer(xp), GetPointer(ctx));
        if(xp.GetDouble() == 0) {
            Print("  [PASS] No TS calculation below trigger.");
        } else {
            PrintFormat("  [FAIL] TS calculated prematurely. xp.GetDouble() = %.2f", xp.GetDouble());
            allPassed = false;
        }
        
        // 2. Above trigger
        pricer.OverridePrice(2375.00); // +25.00 profit > +20.00 trigger
        taskCalc.Execute(GetPointer(xp), GetPointer(ctx));
        double targetSL = xp.GetDouble();
        if(targetSL > 2350.00) {
            PrintFormat("  [PASS] TS calculated at trigger. Target SL: %.2f", targetSL);
        } else {
            PrintFormat("  [FAIL] TS calculation failed. Target SL: %.2f", targetSL);
            allPassed = false;
        }
        
        // 3. Apply modification
        taskApply.Execute(GetPointer(xp), GetPointer(ctx));
        if(terminal.GetPositionSL(90001) == targetSL) {
            Print("  [PASS] Position SL updated on terminal.");
        } else {
            PrintFormat("  [FAIL] Terminal SL mismatch. Expected %.2f, got %.2f", targetSL, terminal.GetPositionSL(90001));
            allPassed = false;
        }

        return allPassed;
    }
};

#endif