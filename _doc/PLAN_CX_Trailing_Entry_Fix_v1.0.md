# Design Plan - Trailing Entry Rebound Placement Fix & Debugging Logger (v1.0)

This document describes the design changes to fix the trailing entry rebound positioning failure in ATSE (MQL5).

## 1. Problem Definition
When pending orders in trailing entry state (`SESSION_TRAILING_ENTRY`) encounter a reverse price movement greater than or equal to `te_step`, the rebound logic executes, but the position is not successfully opened. The system remains in a pending state, and the order is either deleted without entering or gets replaced by another pending order.

## 2. Root Cause Analysis
1. **Order Type Preservation**: When a rebound is detected, the pending limit order is deleted. However, the signal's order type (`sig.GetType()`) is not changed to `ORDER_MARKET` before resubmission, causing the broker request to be generated as a limit order again.
2. **Obsolete Prices**: The execution price, SL, and TP of the signal are not recalculated. This results in the resubmitted order using the obsolete limit prices.
3. **Position Selection Mismatch**: `CXOrderManager` sets the signal ticket to `ResultDeal()` instead of `ResultOrder()` for market orders. In MT5, positions must be selected using the order ticket (`ResultOrder()`), which makes `IsPositionExists` return false.
4. **Missing Self-Healing Scanner**: The position scanner `CXPositionManager::ScanAndBind` does not update the ticket for existing sessions when their tickets mismatch.
5. **No Status Synchronization**: In `CXTaskPending_R_Apply.mqh`, the signal status is not set to `XE_EXECUTED` (10) after successful fallback entry.

## 3. Proposed Fixes

### A. Pending Request Application (`CXTaskPending_R_Apply.mqh`)
When a rebound triggers (`flag == 10`):
- Update the signal type: `sig.SetType(ORDER_MARKET);`
- Fetch the current market price and recalculate price open, SL, and TP using `priceMgr` and validate using `guard`.
- Set the recalculated parameters to the signal object.
- Call `orderMgr.ExecuteEntry(xp)`.
- If successful, set `sig.SetStatus(XE_EXECUTED);` and return `SESSION_ACTIVE`.

### B. Order Manager (`CXOrderManager.mqh`)
In `ExecuteEntry`, set the ticket to:
```mql5
ulong ticket = m_terminal.GetLastResultOrder();
if(ticket == 0) ticket = m_terminal.GetLastResultDeal();
sig.SetTicket(ticket);
```

### C. Position Manager (`CXPositionManager.mqh`)
In `ScanAndBind`, add an `else` block to auto-heal existing sessions by updating their signal's ticket if a position with the matching comment/SID is found with a different ticket:
```mql5
} else {
    ICXSignal* sig = existing.GetSignal();
    if(IS_VALID(sig) && sig.GetTicket() != ticket) {
        sig.SetTicket(ticket);
        XP_LOG_OK(xp, StringFormat("[POS-MANAGER-SCAN] Updated session ticket from order/deal to active position ticket. Ticket:%I64u, SID:%s", ticket, sid));
    }
}
```

### D. Complement Trailing Debugging Logger
- **Extremity Logging (`CXTaskPending_L_Extreme.mqh`)**: Trace new extremities.
- **Rebound Logging (`CXTaskPending_L_Rebound.mqh`)**: If trailing is active, print current price, extreme value, and current gap relative to the target `TE_STEP` on significant changes.

---

## 4. Verification Plan

### Automated Verification
- Compile `ATS.mq5` and `ATSTestRunner.mq5`.
- Verify they compile with `0 errors, 0 warnings`.
- Run the unit tests (`TestTrailingEntry`).

### Manual Verification
- Deploy `ATS.ex5` to MT5 terminal experts.
- Inject a Buy/Sell signal with trailing entry enabled.
- Verify that a market position is opened immediately when a rebound occurs.
- Verify ticket mapping and active position color changes on the chart.
