# Report - Trailing Entry & Limit Fill Logic Integration (v1.0)

This report details the architectural design, precision logic, and verification of the Trailing Entry (rebound fallback) and Limit Fill detection systems implemented in the ATSE MQL5 project.

---

## 1. System Architecture (L-P-R-V-P Pipeline)

The Trailing Entry (TE) logic is orchestrated within the `ORD_TRACKING` state inside the session pipeline. It runs sequentially through five hyper-atomic micro-tasks to monitor, improve, trigger, and execute pending orders:

| Phase | Task Name | Class / Implementation | Responsibility |
| :--- | :--- | :--- | :--- |
| **Verify (V)** | `Pending_V_Sync` | [CXTaskPending_V_Sync](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_V_Sync.mqh) | Synchronizes the database status with the physical broker terminal. |
| **Logic (L)** | `Pending_L_Extreme` | [CXTaskPending_L_Extreme](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Extreme.mqh) | Tracks and updates the most favorable price extremity (minimum for BUY, maximum for SELL). |
| **Logic (L)** | `Pending_L_Improve` | [CXTaskPending_L_Improve](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Improve.mqh) | Dynamically computes and pushes back the pending order price (at M1 bar close) to maintain safety margins. |
| **Logic (L)** | `Pending_L_Rebound` | [CXTaskPending_L_Rebound](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Rebound.mqh) | Calculates the reverse movement from the recorded extreme. Triggers fallback if rebound $\ge$ `te_step`. |
| **Request (R)** | `Pending_R_Apply` | [CXTaskPending_R_Apply](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_R_Apply.mqh) | Deletes the pending order, updates parameters, and executes the immediate market fallback position entry. |

---

## 2. Core Logical Correctness Mechanics

### A. Rebound Fallback & Safety Guard Bypass (`v1.3.1`)
The order manager implements a strict safety guard in `v18.8` to prevent duplicate orders (`sig.GetTicket() > 0` or `sig.GetStatus() >= XE_IN_TRANSIT` aborts new orders). During a rebound market entry, the signal still holds the ticket of the deleted pending order.
*   **Solution**: Before invoking `ExecuteEntry()`, the application explicitly calls `sig.SetTicket(0)` and `sig.SetStatus(XE_READY)`. This atomic reset allows the market order to bypass the safety guard.
*   **Price Recalculation**: The entry price is updated to the current market price, and the SL/TP values are recalculated based on it, with StopLevel checks applied by `guard`.
*   **Tagging**: Successful execution writes `"ENTRY_TE_REBOUND"` to the signal tag.

### B. Limit Fill Detection & Overwrite Prevention
Limit Fill occurs when the broker fills the pending limit order directly before a rebound fallback is triggered. This is detected post-facto by `CXPositionManager::ScanAndBind`.
*   **Ticket Mismatch**: If the scanned terminal position ticket differs from the signal's pending ticket, the scanner binds the new ticket.
*   **Gated Tagging**: The tag `"LIMIT_FILL"` and status transition to `XE_EXECUTED` (10) are only applied if the signal status is still pending (`sig.GetStatus() < XE_EXECUTED`).
*   **Benefit**: This prevents overwriting the `"ENTRY_TE_REBOUND"` tag with `"LIMIT_FILL"` when the scanner aligns the ticket for rebound positions.

---

## 3. Concrete Scenario Mapping (GOLD BUY Example)

Given:
*   Intended Price: **$2350.00**
*   `te_start` (Activation): **300 pt ($3.00)** $\rightarrow$ Activation Price: **$2347.00**
*   `te_step` (Rebound): **100 pt ($1.00)**
*   `te_limit` (Safety Limit): **500 pt ($5.00)**

```
               [Price Signal: $2350.00] 
                          │
  (Price Drops)           ▼
               [Activation Line: $2347.00] (TE_Active_SID set to 1, Extreme tracking begins)
                          │
  (Drops Further)         ▼
               [Extreme Price: $2343.00] (Extreme tracking line updates)
                          │
  (Rebounds Up)           ▼
               [Current Price: $2344.10] (Rebound = 110 points >= te_step)
                          │
                          ▼
               [Trigger Market Fallback] ──> Delete Pending ──> Reset Ticket ──> Market BUY
                                              (Tag: ENTRY_TE_REBOUND)
```

### Path 1: Rebound Market Entry (`ENTRY_TE_REBOUND`)
1.  Price drops past **$2347.00** $\rightarrow$ Trailing Entry activates.
2.  Price drops to **$2343.00** (recorded as extreme) and then rebounds to **$2344.10**.
3.  Rebound of 110 points triggers market fallback (`flag == 10`).
4.  `Pending_R_Apply` deletes the pending limit order, clears ticket/status, recalculates SL/TP based on $2344.10, and opens a market BUY position.
5.  Tag is written as `"ENTRY_TE_REBOUND"`.

### Path 2: Limit Fill Entry (`LIMIT_FILL`)
1.  Price drops to **$2345.00** (where the limit order resides) and immediately fills due to a spike.
2.  `CXPositionManager::ScanAndBind` detects the new position ticket ($T_B$) which does not match the signal's pending ticket ($T_A$).
3.  Since the signal status is still pending, it writes `"LIMIT_FILL"` to the tag, updates status to `XE_EXECUTED` (10), and binds the new ticket $T_B$.

---

## 4. Verification & Deployment Outcomes

*   **Main EA (`ATS.mq5`)**: Compiled successfully (`Result: 0 errors, 0 warnings`).
*   **Unit Tests (`ATSTestRunner.mq5`)**: Compiled successfully (`Result: 0 errors, 0 warnings`).
*   **Deployment**: The updated binary was successfully deployed to all 3 active MT5 terminal instances:
    1.  `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\02BDD49992D399F5E59DC5E74895ADF0\MQL5\Experts\ATS.ex5`
    2.  `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\45DAB6AE8D80995937F3ECF12C78687A\MQL5\Experts\ATS.ex5`
    3.  `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\540829AD6BE27960E4557E2CFD5C69E0\MQL5\Experts\ATS.ex5`
