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
        sig.SetType(ORDER_TYPE_BUY);
        sig.SetPriceOpen(1.1000);
        sig.SetTSStart(20); // TS Start at +20pt
        sig.SetTSStep(5);   // TS Step 5pt
        sig.SetTicket(90001);
        sig.SetSid("TEST-TS-01");
        xp.SetSignal(GetPointer(sig));
        
        // Inject physical position
        terminal.InjectMockAsset(true, 90001, "TEST-TS-01", "EURUSD", 1001, CX_DIR_BUY, 0.1, 1.1000, 0, 0);
        
        CXTaskAlphaCalc taskCalc;
        CXTaskAlphaApply taskApply;
        
        // 1. Below trigger
        pricer.OverridePrice(1.1010); // +10pt < 20pt
        taskCalc.Execute(GetPointer(xp), GetPointer(ctx));
        if(xp.GetDouble() == 0) {
            Print("  [PASS] No TS calculation below trigger.");
        } else {
            PrintFormat("  [FAIL] TS calculated prematurely. xp.GetDouble() = %.5f", xp.GetDouble());
            allPassed = false;
        }
        
        // 2. Above trigger
        pricer.OverridePrice(1.1025); // +25pt > 20pt
        taskCalc.Execute(GetPointer(xp), GetPointer(ctx));
        double targetSL = xp.GetDouble();
        if(targetSL > 1.1000) {
            PrintFormat("  [PASS] TS calculated at trigger. Target SL: %.5f", targetSL);
        } else {
            PrintFormat("  [FAIL] TS calculation failed. Target SL: %.5f", targetSL);
            allPassed = false;
        }
        
        // 3. Apply modification
        taskApply.Execute(GetPointer(xp), GetPointer(ctx));
        if(terminal.GetPositionSL(90001) == targetSL) {
            Print("  [PASS] Position SL updated on terminal.");
        } else {
            PrintFormat("  [FAIL] Terminal SL mismatch. Expected %.5f, got %.5f", targetSL, terminal.GetPositionSL(90001));
            allPassed = false;
        }

        return allPassed;
    }
};

#endif