# Task List - ATSE MQL5 CXUI Error Fixes & Limit Price Optimization (v1.1)

- [x] UI Component Fixes (`CXUI.mqh`)
  - [x] Implement signal direction color coding in Slot Line 1:
    - [x] BUY active position: `clrDodgerBlue`
    - [x] BUY pending order: `clrLightSkyBlue`
    - [x] SELL active position: `clrTomato`
    - [x] SELL pending order: `clrLightCoral`
    - [x] Default: `clrGold` (position) / `clrWheat` (pending)
  - [x] Query and display actual pending order price by ticket:
    - [x] Query `assetMgr.GetCurrentPriceOpen(ticket, false)` if `ticket > 0` and `assetMgr` is valid
    - [x] Fall back to `sig.GetPriceOpen()`
    - [x] Fall back to `sig.GetPriceSignal()`
  - [x] Update `Refresh()` and `UpdateSlot()` signature/calls to pass `assetMgr`
- [x] Execution Component Fixes (`CXTaskEntry_L_Price.mqh`)
  - [x] Standard limit/stop orders (`ORDER_LIMIT` or `ORDER_STOP`) should bypass dynamic calculation and use `sig.GetPriceSignal()` directly
- [x] Verification
  - [x] Compile ATSE using `build_atse.ps1`
  - [x] Compile E2E scenarios using `build_atse.ps1 -File "CXTradeTest\CXScenarioRunner.mq5"`
  - [x] Deploy and verify visually on the chart
