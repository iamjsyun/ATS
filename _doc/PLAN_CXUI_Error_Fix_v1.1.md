# Implementation Plan - ATSE MQL5 CXUI Error Fixes & Limit Price Optimization (v1.1)

This plan outlines the fixes for the ATSE MQL5 project (excluding ATSA) regarding signal direction coloring, LIMIT price display, and standard limit/stop order price calculation.

## Proposed Changes

### ATSE UI Component (MQL5)

#### [MODIFY] [CXUI.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Platform/UI/CXUI.mqh)
1. **Directional Color Coding**:
   - Update `UpdateSlot` to color `Line1` (which displays the SID and state) based on signal direction and session state (pending vs. position):
     - **BUY** (`CX_DIR_BUY`): `clrDodgerBlue` (for active position) / `clrLightSkyBlue` (for pending order).
     - **SELL** (`CX_DIR_SELL`): `clrTomato` (for active position) / `clrLightCoral` (for pending order).
     - **Default**: `clrGold` / `clrWheat`.
2. **LIMIT Price Display Correction**:
   - Update the `LIMIT` price output in `Line2` to show `sig.GetPriceOpen() > 0 ? sig.GetPriceOpen() : sig.GetPriceSignal()`. This ensures the UI displays the actual pending limit order price once placed on the broker terminal.


3. order asset에서 limit price 값 오류
  - 대기오더 접수가 
  - if(p0 <= 0) p0 = sig.GetPriceOpen(); 가격대신 티켓으로 조회한 대기 오던 자산의 진입가 표시
  -
4. asset state가 트레일링 상태로 진입하면
-  LIMIT: 1.00        ESTART: 4446.97    ESTEP: 0.30 라인의 색상 clrRed로 변경
-  오더,포지션이 트레일링 상태임을 직관적으로 식별할 수 있는 UI 강조 표출 설계 보완  
---

### ATSE Execution Component (MQL5)

#### [MODIFY] [CXTaskEntry_L_Price.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Entry/CXTaskEntry_L_Price.mqh)
- For standard limit/stop orders (`ORDER_LIMIT` or `ORDER_STOP`), set `execPrice` directly to `sig.GetPriceSignal()` (which contains the pre-calculated price from ATSA) rather than dynamically recalculating it from the live market price using `priceMgr.CalculateExecPrice()`.
- Preserve dynamic calculation for market (`ORDER_MARKET`) and trailing limit (`ORDER_LIMIT_TRAILING`) orders.

---

## Verification Plan

### Automated Tests
- Build `ATS.mq5` using `powershell.exe -ExecutionPolicy Bypass -File .\build_atse.ps1` and verify there are `0 errors, 0 warnings`.
- Build `CXScenarioRunner.mq5` using `powershell.exe -ExecutionPolicy Bypass -File .\build_atse.ps1 -File "CXTradeTest\CXScenarioRunner.mq5"` and verify it compiles successfully.

### Manual Verification
- Deploy the compiled EA. Inject buy/sell signals and verify the dashboard Slot Line 1 text color:
  - BUY pending: `LightSkyBlue`
  - BUY position: `DodgerBlue`
  - SELL pending: `LightCoral`
  - SELL position: `Tomato`
- Verify that standard limit orders display the exact limit price under `LIMIT` in Slot Line 2.
