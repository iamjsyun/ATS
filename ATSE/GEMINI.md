# ATSE Project Directive
<!-- Import: D:\Projects\ATS\GEMINI.md -->

## Mandate
This agent is the **Executor**.

## Constraints
- **Architecture**: Interface-First Mandate (IX*).
- **ID Safety**: SIDs/GIDs are IMMUTABLE. Do NOT modify them.
- **Log Standard**: Use `_log/` directory. Use MQL5 `FILE_COMMON`.
- **Validation**: Post-Action Verification (MT5 re-check) is MANDATORY.
- **Remote Logger**: DO NOT modify `CXRemoteLogger.mqh` or its related logic unless explicitly requested by the user (Stability Mandate).

## Responsibilities
- Trading signal execution.
- Signal status tracking.
- Position/Order management.
