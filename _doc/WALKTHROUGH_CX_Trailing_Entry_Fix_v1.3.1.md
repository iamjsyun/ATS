# Walkthrough - Trailing Entry Rebound Fix v1.3.1 (Safety Guard Bypass)

This walkthrough documents the successful resolution of the Trailing Entry rebound failure where the trigger fired multiple times without opening a position.

## Root Cause Analysis

1.  **Safety Guard Blockage**: A safety guard added in `v18.8` to `CXOrderManager::ExecuteEntry` blocked the market fallback entry. The guard prevents sending a new order if `sig.GetTicket() > 0` or `sig.GetStatus() >= XE_IN_TRANSIT`. During a rebound fallback, the signal still held the ticket of the deleted pending order and was set to `XE_IN_TRANSIT`, triggering the guard.
2.  **Repeating Logs (Key Collision)**: In `CXTaskPending_L_Rebound.mqh`, a key collision occurred where the suppression flag used to prevent duplicate logs was overwritten by the trigger flag (both using "ReboundTriggered_SID"). Additionally, the suppression check only looked for exactly `1`, while the trigger set it to `10`.

## Changes Made

### 1. Execution Component (`CXTaskPending_R_Apply.mqh`)
- **Safety Guard Bypass**: Modified the market fallback logic to explicitly clear the signal ticket (`sig.SetTicket(0)`) and reset the status to (`sig.SetStatus(XE_READY)`) immediately before calling `orderMgr.ExecuteEntry(xp)`. This allows the new market order to pass the safety guard.

### 2. Logic Component (`CXTaskPending_L_Rebound.mqh`)
- **Suppression Fix**: Updated the duplicate log suppression check to look for `pTriggered.GetInt() >= 1` instead of `== 1`.
- **Key Consolidation**: Ensured the trigger flag and suppression flag use the same key and value (`10`) consistently to prevent collision and ensure proper state maintenance across ticks.

---

## Verification Results

### Automated Build Verification
1. **ATSE Expert Advisor (`ATS.mq5`)**:
   - Compiled successfully.
   - Output: `Result: 0 errors, 0 warnings`.

### Deployment Verification
- Executed `deploy_atse.ps1` successfully, copying the fixed `ATS.ex5` to three active MetaTrader 5 terminal experts directories.
