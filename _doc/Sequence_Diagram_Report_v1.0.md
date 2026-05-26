# ATSE Sequence Diagram Report (v1.0)

## 1. Executive Summary

This report presents a runtime sequence analysis of the **ATSE (Active Trading State Engine)**. It visualizes the chronological flow of messages, method invocations, and database transitions between core components:
1. **CXSignalWatcher**: Discovers and bootstraps incoming signals.
2. **CXTradingSession & Workflow Tasks**: Executes the hyper-atomic step sequences.
3. **CXTerminalPlatform**: Decouples ATSE from MT5 API and broker networks.
4. **CXSignalRepository (SQLite)**: Acts as the Single Source of Truth (SSOT).

---

## 2. Phase 1: Discovery & Session Spawn

This sequence outlines how the **Watcher** queries new entry intents from the DB, validates constraints using `CXGuard`, and registers a sandboxed `CXTradingSession`.

```mermaid
sequenceDiagram
    autonumber
    participant DB as SQLite (DB/Repo)
    participant Watcher as CXSignalWatcher
    participant Guard as CXGuard
    participant SessionMgr as CXSessionManager
    participant Session as CXTradingSession

    Watcher->>DB: GetActiveSignals()
    DB-->>Watcher: Return raw XSignal models

    loop For each signal
        Watcher->>Guard: Check(xp, ctx)
        alt Validation Fails
            Guard-->>Watcher: Return false & SetError()
            Watcher->>DB: UpdateStatus(sig, XE_ERROR, errMsg)
        else Validation Passes
            Guard-->>Watcher: Return true
            Watcher->>SessionMgr: SpawnSession(sig)
            create participant Session
            SessionMgr->>Session: New(sig, ctx)
            SessionMgr->>DB: UpdateStatus(sig, XE_PENDING_REQ, "Session Spawned")
            SessionMgr-->>Watcher: Return Session handle
        end
    end
```

---

## 3. Phase 2: Order Execution & Remapping

This sequence details the execution of `SESSION_READY` and `SESSION_EXECUTING`. The workflow tasks calculate prices using `ICXPriceManager` and dispatch orders via `IXTerminalPlatform`, remapping MT5 tickets back to the DB.

```mermaid
sequenceDiagram
    autonumber
    participant Session as CXTradingSession
    participant Task as CXTaskEntry_R_Order
    participant PriceMgr as ICXPriceManager
    participant Platform as CXTerminalPlatform
    participant Broker as MT5 Terminal/Broker
    participant DB as SQLite (DB/Repo)

    Note over Session: State: SESSION_READY
    Session->>Session: Run Step_Validating
    Note over Session: Transition to SESSION_EXECUTING

    Session->>Task: Execute(xp, ctx)
    Task->>PriceMgr: CalculateExecPrice(xp, symbol, dir, type, offsetPts)
    PriceMgr-->>Task: Return normalized execPrice
    Task->>PriceMgr: CalculateSL() & CalculateTP()
    PriceMgr-->>Task: Return normalized SL/TP prices

    Task->>Platform: OrderOpen/PositionOpen(xp, sig, execPrice, SL, TP)
    Platform->>Platform: SetExpertMagicNumber(magic)
    Platform->>Broker: OrderSend(request)
    Broker-->>Platform: Return MqlTradeResult (Ticket)
    
    alt Order Accepted
        Platform->>Platform: Log [EXEC-ENTRY] Success
        Platform-->>Task: Return true (Success)
        Task->>sig: SetTicket(newTicket)
        Task->>sig: SetStatus(XE_IN_TRANSIT)
        Task->>DB: UpdateStatus(sig, XE_IN_TRANSIT, "Ticket Obtained")
    else Order Rejected
        Platform->>Platform: Log [EXEC-ENTRY-FAIL] Error
        Platform-->>Task: Return false (Fail)
        Task->>sig: SetStatus(XE_ERROR)
        Task->>DB: UpdateStatus(sig, XE_ERROR, errorDesc)
    end
```

---

## 4. Phase 3: Trailing Entry (Optimization)

This sequence outlines the active trailing entry phase (`SESSION_TRAILING_ENTRY`). The engine tracking extreme prices, rebounding triggers, and dynamically shifting limit orders in the MT5 pool.

```mermaid
sequenceDiagram
    autonumber
    participant Session as CXTradingSession
    participant Rebound as CXTaskPending_L_Rebound
    participant Improve as CXTaskPending_L_Improve
    participant Apply as CXTaskPending_R_Apply
    participant PriceMgr as ICXPriceManager
    participant Platform as CXTerminalPlatform
    participant Broker as MT5 Terminal/Broker
    participant DB as SQLite (DB/Repo)

    Note over Session: State: SESSION_TRAILING_ENTRY
    Session->>Rebound: Execute(xp, ctx)
    Rebound->>PriceMgr: GetLiquidationPrice(symbol, dir)
    PriceMgr-->>Rebound: Return currentPrice
    Rebound->>Rebound: Track extreme price & check rebound (>= TEStep)
    Rebound-->>Session: Return TASK_CONTINUE (Triggered=True/False)

    Session->>Improve: Execute(xp, ctx)
    Improve->>Improve: Calculate new target limit price (>= TEStep)
    Improve-->>Session: Return TASK_CONTINUE & set newPrice in xp

    Session->>Apply: Execute(xp, ctx)
    Apply->>PriceMgr: CalculateSL() & CalculateTP()
    PriceMgr-->>Apply: Return normalized SL/TP
    Apply->>Platform: OrderModify(ticket, newPrice, SL, TP)
    Platform->>Broker: OrderModify(ticket, ...)
    Broker-->>Platform: Return result
    Platform-->>Apply: Return success
    Apply->>DB: UpdateStatus(sig, XE_PENDING_PLACED, "Order Modified")
    Apply-->>Session: Return TASK_CONTINUE
```

---

## 5. Phase 4: Position Trailing & Profit Protection (TS/Alpha)

When the pending order is filled, the session transitions to `SESSION_ACTIVE`. It tracks dynamic price movements, checks profit margins, and updates trailing Stop Loss levels.

```mermaid
sequenceDiagram
    autonumber
    participant Session as CXTradingSession
    participant TSWatch as CXTaskActive_TS_TriggerWatch
    participant AlphaCalc as CXTaskAlphaCalc
    participant AlphaApply as CXTaskAlphaApply
    participant Platform as CXTerminalPlatform
    participant Broker as MT5 Terminal/Broker
    participant DB as SQLite (DB/Repo)

    Note over Session: State: SESSION_ACTIVE
    Session->>TSWatch: Execute(xp, ctx)
    TSWatch->>Platform: GetPositionProfit(ticket)
    Platform-->>TSWatch: Return currentProfit
    alt Profit >= TSStart
        TSWatch->>sig: SetStatus(XE_EXECUTED)
        TSWatch-->>Session: Transition to SESSION_TRAILING_STOP
    else
        TSWatch-->>Session: Return TASK_CONTINUE
    end

    Note over Session: State: SESSION_TRAILING_STOP
    Session->>AlphaCalc: Execute(xp, ctx)
    AlphaCalc->>AlphaCalc: Track Peak & calculate potential SL improvement (>= TSStep)
    AlphaCalc-->>Session: Return TASK_CONTINUE & set newSL in xp

    Session->>AlphaApply: Execute(xp, ctx)
    AlphaApply->>Platform: PositionModify(ticket, newSL, currentTP)
    Platform->>Broker: PositionModify(ticket, ...)
    Broker-->>Platform: Return result
    Platform-->>AlphaApply: Return success
    AlphaApply->>DB: UpdateStatus(sig, XE_EXECUTED, "SL Improved")
```

---

## 6. Phase 5: Termination & Sweep

The termination sequence manages position closures (triggered by DB exit intent, broker stop-out, or manual termination). It sweeps lingering orders to guarantee absolute cleanup.

```mermaid
sequenceDiagram
    autonumber
    participant Session as CXTradingSession
    participant IntentWatch as CXTaskIntentWatch
    participant ExitPrepare as CXTaskExit_L_Prepare
    participant ExitOrder as CXTaskExit_R_Order
    participant Platform as CXTerminalPlatform
    participant Broker as MT5 Terminal/Broker
    participant DB as SQLite (DB/Repo)

    Session->>IntentWatch: Execute(xp, ctx)
    alt Manual Close (Asset Disappeared)
        IntentWatch->>sig: SetStatus(XE_CLOSED_MANUAL)
        IntentWatch->>sig: SetXAExit(XA_CLOSED_COMPLETED)
        IntentWatch->>DB: ForceUpdateIntent(sig)
        IntentWatch-->>Session: Return SESSION_CLOSED (Fast-Track)
    else DB Exit Intent Detected (xa_exit=1)
        IntentWatch-->>Session: Return SESSION_LIQUIDATING
    end

    Note over Session: State: SESSION_LIQUIDATING
    Session->>ExitPrepare: Execute(xp, ctx)
    ExitPrepare->>sig: SetStatus(XE_CLOSED_SIGNAL)
    ExitPrepare-->>Session: Return TASK_CONTINUE

    Session->>ExitOrder: Execute(xp, ctx)
    ExitOrder->>Platform: SweepBySid(magic, sid)
    Platform->>Platform: Sweep position & pending order tickets
    Platform->>Broker: PositionClose(ticket) / OrderDelete(ticket)
    Broker-->>Platform: Return success
    Platform-->>ExitOrder: Return true (All Cleared)
    ExitOrder->>DB: UpdateStatus(sig, XE_CLOSED_SIGNAL, "Closed Completed")
    ExitOrder-->>Session: Return SESSION_CLOSED
```
