# Task List - Trailing Entry Rebound Fix v1.3.1 (Safety Guard Bypass)

- [x] Fix repeating logs in `CXTaskPending_L_Rebound.mqh`
  - [x] Change suppression check to `>= 1` to handle key collision.
  - [x] Consistent key usage for trigger flag.
- [x] Fix Market Fallback blockage in `CXTaskPending_R_Apply.mqh`
  - [x] Clear signal ticket (`SetTicket(0)`) before `ExecuteEntry`.
  - [x] Reset signal status (`SetStatus(XE_READY)`) to bypass `v18.8` safety guard.
- [x] Verification
  - [x] Compile `ATS.mq5` using `build_atse.ps1`
  - [x] Deploy EA using `deploy_atse.ps1`
