# REPORT: Full Lifecycle Orchestration & State Transition Design (v1.3)

This report details the standardized architectural matrix, sequence workflows, state transitions, execution pipelines, database logging systems, and event-driven pulse optimization strategy of the ATSE engine.

---

## 1. Stage, Sequence, and Task Structure Matrix

The trading engine manages the lifecycle using five high-level execution Stages. All task class names follow the strict `CXTask{Stage}_{Phase}_{Name}` naming standard.

| Stage                  | Sequence ID / State        | Key Standardized Tasks                                                                                                                   | Trailing Engine Role      | Responsibility                                                                                                                                                                                             |
| :--------------------- | :------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- | :------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **StageDiscovery**     | `SESSION_DISCOVERY` (0)    | `CXStageEntryDiscovery`<br>`CXStageExitDiscovery`                                                                                        | *None*                    | Discovers signals with `xa_entry=1` or `xa_exit=1` from SQLite database.                                                                                                                                   |
| **StageEntryExecute**  | `SESSION_PENDING` (3)      | `CXTaskPending_V_Sync`<br>`CXTaskPending_L_Extreme`<br>`CXTaskPending_L_Improve`<br>`CXTaskPending_L_Rebound`<br>`CXTaskPending_R_Apply` | Active (Entry Trailing) | Validates pending order status, tracks extremities, dynamically pushes back limit orders, and triggers market fallback on rebound.                                                                         |
| **StageActiveExecute** | `SESSION_ACTIVE` (10)      | `CXTaskActive_L_TS_TriggerWatch`<br>`CXTaskActive_V_Terminal`<br>`CXTaskIntentWatch`                 | Trigger Watch    | **`TS_TriggerWatch`**: Configures engine to watch profit >= `ts_start` and transitions to `POS_TRAILING` (15). |
| **StagePositionTrailing** | `SESSION_TRAILING` (15)      | `CXTaskAlphaCalc`<br>`CXTaskAlphaApply`<br>`CXTaskActive_V_Terminal`                 | Active (Exit Trailing)    | **`AlphaCalc`**: Updates peak price to compute SL adjustments.<br>**`AlphaApply`**: Submits target SL/TP modification requests. |
| **StageExitExecute**   | `SESSION_LIQUIDATING` (20) | `CXTaskExit_L_Prepare`<br>`CXTaskExit_P_Lock`<br>`CXTaskExit_R_Order`<br>`CXTaskExit_V_Terminal`<br>`CXTaskExit_P_Finalize`              | *None*                    | Deletes orders or closes physical positions on the broker terminal to finish the exit loop.                                                                                                                |

---

## 2. Orchestration State Mapping & DSL Configuration

To align DSL state labels with C++ enum values, states are registered in `AppOrchestrator::RegisterStandardNames`:
* **`ORD_TRACKING`**: Maps to `ORD_TRAILING` (5) -> Transitions to 10 (Active) or 20 (Liquidation)
* **`POS_MONITORING`**: Maps to `POS_ACTIVE` (10) -> Transitions to 15 (Trailing) or 20 (Liquidation)
* **`POS_TRAILING`**: Maps to 15 -> Transitions to 20 (Liquidation)
* **`SESSION_LIQUIDATING`**: Maps to `SESSION_LIQUIDATING` (20)
* **`SYS_CLOSED`**: Maps to `SYS_CLOSED` (30)
* **`SYS_ERROR`**: Maps to `SYS_ERROR` (99)

---

## 3. Event-Driven Pulse Performance Optimization Strategy

To maximize execution efficiency and reduce CPU latency, engine tasks are segregated across MetaTrader 5 event channels.

### A. Non-Blocking Database Polling (`OnTimer`)
- **Design**: Restrict `StageDiscovery` database polling to a fixed `OnTimer` pulse (e.g., 400ms). Use memory-cached session parameters for tasks running on `OnTick` to bypass physical DB disk access. Handles System Health Checks and Timeout Guards.

### B. High-Frequency Trailing Engine (`OnTick`)
- **Design**: `StageEntryExecute` (Limit tracking) and `StageActiveExecute` (Trailing Stop / Alpha calculations) are isolated and bound directly to `OnTick`. This ensures real-time price tracking. Skips execution if prices remain unchanged (Deduplication filter).

### C. State Fast-Tracking (`OnTradeTransaction`)
- **Design**: Intercept transaction confirmations in `OnTradeTransaction` and immediately invoke `Pulse(transParam)`. Instantly transitions the state machine (`XE_PENDING_PLACED` -> `XE_EXECUTED` or `XE_CLOSED`), bypassing timer delays entirely.

---

## 4. State Transition Diagram

```mermaid
stateDiagram-v2
    [*] --> XE_READY : Signal Discovered (xa_entry=1)
    
    state "Orchestration: SESSION_PENDING (ORD_TRACKING)" as pending {
        XE_READY --> XE_PENDING_REQ : Call Broker (ExecuteEntry)
        XE_PENDING_REQ --> XE_IN_TRANSIT : Broker Accepted Request
        XE_IN_TRANSIT --> XE_PENDING_PLACED : Pending Order Placed
    }

    state "Orchestration: SESSION_ACTIVE (POS_MONITORING)" as active {
        XE_PENDING_PLACED --> XE_EXECUTED : Limit Order Filled / Rebound Entry
        XE_PENDING_PLACED --> XE_READY : Rebound Fallback Reset
        XE_EXECUTED --> POS_TRAILING : Profit >= ts_start (TS Triggered)
    }

    state "Orchestration: POS_TRAILING" as trailing {
        POS_TRAILING --> TS_Active : Alpha Tracking
        TS_Active --> TS_Triggered : Rebound >= ts_step (Stop Out)
    }

    state "Orchestration: SESSION_LIQUIDATING" as exit {
        TS_Triggered --> XE_CLOSED_SIGNAL : Position Closed (xa_exit=2)
        XE_EXECUTED --> XE_CLOSED_SIGNAL : Exit Signal (xa_exit=1)
        POS_TRAILING --> XE_CLOSED_SIGNAL : Exit Signal (xa_exit=1)
        pending --> XE_CLOSED_SIGNAL : Exit Signal (xa_exit=1)
    }

    XE_CLOSED_SIGNAL --> [*]
```

---

## 5. SQLite Database Audit Logging (`atse_log`)

To maintain clean and audit-ready lifecycle records per session, the engine implements structured logging to SQLite.

### A. Schema Definition
The table is initialized automatically upon database connection:
```sql
CREATE TABLE IF NOT EXISTS atse_log (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    sid       TEXT NOT NULL,
    created   DATETIME DEFAULT (datetime('now', 'localtime')),
    level     TEXT NOT NULL,
    msg       TEXT NOT NULL
);
```

### B. Standardized Audit Payload
Audit logs contain a standardized suffix payload tracking the state and converted price metrics:
`[Description] | SID:{sid}, Stage:{stage}, Task:{task}, SeqState:{state}, XA:({xa_entry},{xa_exit}), XE:{xe_status}, Lot:{lot:F2}, SL:{sl:F2}, TP:{tp:F2}, Parameters:[TE_Start:{te_start:F0}(P:{te_start_price:F2}), TE_Step:{te_step:F0}, TE_Limit:{te_limit:F0}(P:{te_limit_price:F2}), IK_Start:{ikte_start:F0}(P:{ikte_start_price:F2}), IK_Step:{ikte_step:F0}], Msg:\"{status_msg}\"`

[[REPORT_Full_Lifecycle_Orchestration_v1.2]]
[[REPORT_Logger_Improvement_Strategy_v1.1]]

[[REPORT_Pulse_Performance_Optimization_v1.0]]