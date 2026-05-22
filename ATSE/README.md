# ATSE (ATS Expert)

ATSE is a MetaTrader 5 (MQL5) Algorithmic Trading System focused on hyper-atomized task execution and high-precision auditability.

## Core Features (v13.5)
- **Universal Audit Format (UAF)**: Standardized logging across all components for 100% traceability.
- **Atomic Binding**: Prevention of duplicate session assignment via immediate DB locking.
- **Exit-First Priority**: Real-time abort of entry sequences upon exit signal detection.
- **History Sync Resilience**: 5-tick retry mechanism for asynchronous MT5 trade history.
- **Self-Test Framework**: CSV-based scenario injection with automated success verification.

## Architecture
- **Interface-First**: All managers (`IXOrderManager`, `IXPositionManager`, etc.) are decoupled via abstract interfaces.
- **Unified Logic**: Shared state management through `ICXContext`.
- **SSOC (Single Source of Calculation)**: Centralized math for price, risk, and inventory.
