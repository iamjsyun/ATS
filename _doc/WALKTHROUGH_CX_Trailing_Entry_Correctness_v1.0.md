# Walkthrough - Trailing Entry and Limit Fill Correctness (v1.0)

This walkthrough documents the execution, compilation, and deployment of trailing entry rebound fallback fixes and limit fill correctness updates in the ATSE MQL5 project.

## Changes Made

### 1. Rebound Entry Correctness (`CXTaskPending_R_Apply.mqh`)
- **Safety Guard Bypass**: Added `sig.SetTicket(0)` and `sig.SetStatus(XE_READY)` right before `orderMgr.ExecuteEntry(xp)` to bypass the `v18.8` safety guard checks inside `CXOrderManager::ExecuteEntry`.
- **Target Tagging**: Added `sig.SetTag("ENTRY_TE_REBOUND")` upon successful execution.
- **Recalculations**: Execution price and SL/TP are dynamically recalculated based on current market prices at rebound, with StopLevel checks applied by `guard`.

### 2. Limit Fill Correctness (`CXPositionManager.mqh`)
- **Gated Tagging**: Added a check `if (sig.GetStatus() < XE_EXECUTED)` in `ScanAndBind` before applying the `"LIMIT_FILL"` tag. This ensures that rebound entries (which are already marked as `XE_EXECUTED` and `"ENTRY_TE_REBOUND"`) are not overwritten with `"LIMIT_FILL"` when the scanner aligns the tickets.
- **Status & DB Sync**: Successfully maps the new position ticket to the session, marks status as `XE_EXECUTED`, and invokes `repo.UpdateStatus(sig)` to sync to the database.

---

## Verification Results

### Automated Build Verification
1. **ATSE Expert Advisor (`ATS.mq5`)**:
   - Compiled successfully.
   - Output: `Result: 0 errors, 0 warnings`.
2. **ATSE Test Runner (`ATSTestRunner.mq5`)**:
   - Compiled successfully.
   - Output: `Result: 0 errors, 0 warnings`.

### Deployment Verification
- Executed `deploy_atse.ps1` successfully, copying `ATS.ex5` to three active MT5 terminal experts folders:
  - `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\02BDD49992D399F5E59DC5E74895ADF0\MQL5\Experts\ATS.ex5`
  - `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\45DAB6AE8D80995937F3ECF12C78687A\MQL5\Experts\ATS.ex5`
  - `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\540829AD6BE27960E4557E2CFD5C69E0\MQL5\Experts\ATS.ex5`
