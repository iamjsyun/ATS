# REPORT: Full Lifecycle Orchestration & State Transition Design (v1.1)

This report details the standardized architectural matrix, sequence workflows, state transitions, and execution pipelines of the ATSE engine—covering the entire lifecycle from signal detection to exit/liquidation, incorporating the newly integrated `CXTrailingEngine`.

---

## 1. Stage, Sequence, and Task Structure Matrix

The trading engine manages the lifecycle using four high-level execution Stages, each mapping to specific Sequence IDs and processing pipelines of atomic Tasks. All task class names follow the strict `CXTask{Stage}_{Phase}_{Name}` naming standard.

| Stage                  | Sequence ID / State        | Key Standardized Tasks                                                                                                                   | Trailing Engine Role      | Responsibility                                                                                                                                                                                             |
| :--------------------- | :------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- | :------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **StageDiscovery**     | `SESSION_DISCOVERY` (0)    | `CXStageEntryDiscovery`<br>`CXStageExitDiscovery`                                                                                        | *None*                    | Discovers signals with `xa_entry=1` or `xa_exit=1` from SQLite database.                                                                                                                                   |
| **StageEntryExecute**  | `SESSION_PENDING` (1)      | `CXTaskPending_V_Sync`<br>`CXTaskPending_L_Extreme`<br>`CXTaskPending_L_Improve`<br>`CXTaskPending_L_Rebound`<br>`CXTaskPending_R_Apply` | Optional (Entry Trailing) | Validates pending order status, tracks extremities, dynamically pushes back limit orders, and triggers market fallback on rebound.                                                                         |
| **StageActiveExecute** | `SESSION_ACTIVE` (5)       | `CXTaskActive_L_TS_TriggerWatch`<br>`CXTaskActive_L_AlphaCalc`<br>`CXTaskActive_R_AlphaApply`<br>`CXTaskActive_P_Closed`                 | Active (Exit Trailing)    | **`TS_TriggerWatch`**: Configures engine to watch profit >= `ts_start`.<br>**`AlphaCalc`**: Updates peak price to compute SL adjustments.<br>**`AlphaApply`**: Submits target SL/TP modification requests. |
| **StageExitExecute**   | `SESSION_LIQUIDATING` (10) | `CXTaskExit_L_Prepare`<br>`CXTaskExit_P_Lock`<br>`CXTaskExit_R_Order`<br>`CXTaskExit_V_Terminal`<br>`CXTaskExit_P_Finalize`              | *None*                    | Deletes orders or closes physical positions on the broker terminal to finish the exit loop.                                                                                                                |

---

## 2. State Transition Diagram

The diagram below maps both the internal signal state (`xe_status`) and the session orchestration states.

```mermaid
stateDiagram-v2
    [*] --> XE_READY : Signal Discovered (xa_entry=1)
    
    state "Orchestration: SESSION_PENDING" as pending {
        XE_READY --> XE_PENDING_REQ : Call Broker (ExecuteEntry)
        XE_PENDING_REQ --> XE_IN_TRANSIT : Broker Accepted Request
        XE_IN_TRANSIT --> XE_PENDING_PLACED : Pending Order Placed
    }

    state "Orchestration: SESSION_ACTIVE" as active {
        XE_PENDING_PLACED --> XE_EXECUTED : Limit Order Filled / Rebound Entry
        XE_PENDING_PLACED --> XE_READY : Rebound Fallback Reset
        
        state "Orchestration: SESSION_TRAILING_STOP" as trailing {
            XE_EXECUTED --> TS_Active : Profit >= ts_start (Engine State: ACTIVE)
            TS_Active --> TS_Triggered : Rebound >= ts_step (Engine State: TRIGGERED)
        }
    }

    state "Orchestration: SESSION_LIQUIDATING" as exit {
        TS_Triggered --> XE_CLOSED_SIGNAL : Position Closed (xa_exit=2)
        XE_EXECUTED --> XE_CLOSED_SIGNAL : Exit Signal (xa_exit=1)
    }

    XE_CLOSED_SIGNAL --> [*]
```

---

## 3. Sequence Diagram (Signal to Liquidation)

This diagram details the sequence of ticks, trailing engine updates, order placements, and position closures.

```mermaid
sequenceDiagram
    autonumber
    participant Watcher as CXStageEntryDiscovery
    participant Session as CXTradingSession
    participant Engine as CXTrailingEngine
    participant Broker as Broker Terminal
    participant DB as SQLite DB

    %% 1. Discovery
    Watcher->>DB: Query signals (xa_entry=1 & xe_status=0)
    DB-->>Watcher: Return Signal (sid)
    Watcher->>Session: Spawn Session Context

    %% 2. Entry Execution
    Session->>Broker: OrderOpen (Pending Limit)
    Broker-->>Session: Return Ticket (T_Pend)
    Session->>DB: Update Status = XE_PENDING_PLACED, Ticket = T_Pend

    %% 3. Active Stage & Trailing Watch
    loop Every Tick
        Session->>Engine: Update(currentPrice)
        alt Engine State changes to ACTIVE
            Engine-->>Session: Return TRAIL_STATE_ACTIVE
            Session->>Session: Transition to SESSION_TRAILING_STOP
        end
    end

    %% 4. Trailing stop execution
    loop Trailing Active
        Session->>Engine: Update(currentPrice)
        alt Peak Price Improves
            Session->>Broker: PositionModify (Adjust SL)
        else Retraction >= ts_step (Engine State: TRIGGERED)
            Engine-->>Session: Return TRAIL_STATE_TRIGGERED
            Session->>Session: Transition to SESSION_LIQUIDATING
        end
    end

    %% 5. Liquidation
    Session->>Broker: PositionClose (T_Active)
    Broker-->>Session: Close Success
    Session->>DB: Update Status = XE_CLOSED_SIGNAL, xa_exit = 2 (COMP)
```

---

## 4. Step-by-Step Process Explanation

### Step 1: Signal Discovery & Spawning (`StageDiscovery`)
- The `CXStageEntryDiscovery` and `CXStageExitDiscovery` stages poll the SQLite `signals` table for any entry records (`xa_entry=1`) or exit records (`xa_exit=1`).
- Once found, a session-specific context (`CXTradingSession`) is spawned to isolate the execution state.

### Step 2: Order Placement & Trailing Entry (`StageEntryExecute`)
- The session submits a pending limit order to the broker.
- If Trailing Entry (진트) is configured, the `CXTaskPending_L_Rebound` task tracks the price drop extreme. On a rebound, it deletes the pending limit order and opens a market position instead (`ENTRY_TE_REBOUND`).

### Step 3: Activation & Trailing Stop (`StageActiveExecute`)
- Once the position is filled (`XE_EXECUTED`), the active stage tracks the running profit.
- `CXTaskActive_L_TS_TriggerWatch` initializes the `CXTrailingEngine` with the position open price, `ts_start`, and `ts_step`.
- When profit reaches `ts_start` points, the engine moves to `TRAIL_STATE_ACTIVE` and the session switches to `SESSION_TRAILING_STOP`.
- `CXTaskActive_L_AlphaCalc` reads the tracked peak price from the engine on every tick.
- `CXTaskActive_R_AlphaApply` updates the SL order (`PositionModify`) as the market moves in favor of the trade.

### Step 4: Retraction & Position Liquidation (`StageExitExecute`)
- When the price retraces by `ts_step` points from the peak, the engine transitions to `TRAIL_STATE_TRIGGERED`.
- The session transitions to `SESSION_LIQUIDATING` (`StageExitExecute`).
- The `CXTaskExit_R_Order` task submits the closing order to the broker, the scanner binds the history ticket, and the repository is finalized with `xa_exit=2` (CLOSED).

Logger 시스템 개선
	SID 별 로그는 sqlite table에 기록하는 설계 검토
	신호 감지 후 SID 확보됨
	감진된 신호 정보와 트레이딩 세션의 중요 관리정보 ,트레일링 변화정보 , 청산 정보의 이벤트별 변화에 따랄 table에 행으로 추가하는 설계
	table : atse_log
	id int auto key
	sid string
	datetime time
	msg string
	