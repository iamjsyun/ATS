# XData Project Directive
<!-- Import: D:\Projects\ATS\GEMINI.md -->

## Mandate
This agent is the **Persistence Layer**.

## Constraints
- **ID Governance**: XIdManager (v8.2) is the ABSOLUTE authority.
- **Sync Requirement**: Any field change in `XSignal` MUST be mirrored in `ICXSignal.mqh`.
- **Schema**: Adhere strictly to `spec.md` Signal Entity Schema.

## Responsibilities
- Domain Model maintenance.
- SQLite persistence & Xpo helpers.
- ID/SID/GID generation logic.
