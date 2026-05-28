# Design Plan - Trailing Entry and Limit Fill Correctness (v1.0)

This plan outlines the alignment of the current MQL5 implementation with the strict specifications for Trailing Entry (rebound market entry) and Limit Fill detection, including correct tagging, safety guard bypassing, and database synchronization.

## 1. Current Implementation vs. Target Specification Analysis

### A. Rebound Market Entry (`CXTaskPending_R_Apply.mqh`)
*   **Current State**:
    *   Deletes the pending order.
    *   Updates order type to `ORDER_MARKET`.
    *   Recalculates execution price and SL/TP based on market price.
    *   Calls `orderMgr.ExecuteEntry(xp)`.
*   **Deficiencies**:
    *   **Bypass Safety Guard**: Does not clear the ticket (`SetTicket(0)`) or reset the status (`SetStatus(XE_READY)`) immediately before execution. This triggers the `v18.8` safety guard in `CXOrderManager::ExecuteEntry`, which blocks execution if the ticket is set or if the status is transit.
    *   **Missing Tagging**: Does not mark the signal's tag as `"ENTRY_TE_REBOUND"`.
*   **Correction Strategy**:
    *   Explicitly invoke `sig.SetTicket(0)` and `sig.SetStatus(XE_READY)` right before `ExecuteEntry`.
    *   Set `sig.SetTag("ENTRY_TE_REBOUND")` upon successful execution.

### B. Limit Fill Detection (`CXPositionManager.mqh`)
*   **Current State**:
    *   Scans the active terminal positions.
    *   If a session exists for the scanned SID, but the ticket differs, it updates the ticket.
*   **Deficiencies**:
    *   **Missing Tagging**: Does not set the signal's tag to `"LIMIT_FILL"`.
    *   **Missing Status Sync**: Does not update status to `XE_EXECUTED` (10) or synchronize it to the repository database via `repo.UpdateStatus(sig)`.
*   **Correction Strategy**:
    *   When `ticket_A != ticket_B` is detected:
        *   Set `sig.SetTag("LIMIT_FILL")`.
        *   Set `sig.SetStatus(XE_EXECUTED)`.
        *   Set `sig.SetStatusMsg("Limit Fill Detected")`.
        *   Invoke `repo.UpdateStatus(sig)`.

---

## 2. Proposed Changes

### [MODIFY] [CXTaskPending_R_Apply.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_R_Apply.mqh)
```mql5
                sig.SetTicket(0);
                sig.SetStatus(XE_READY);
                
                if(orderMgr.ExecuteEntry(xp)) {
                    ulong newTicket = (ulong)sig.GetTicket();
                    sig.SetTag("ENTRY_TE_REBOUND");
                    sig.SetStatus(XE_EXECUTED);
                    sig.SetStatusMsg("Market Fallback Entered");
                    ...
```

### [MODIFY] [CXPositionManager.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Execution/Position/CXPositionManager.mqh)
```mql5
            } else {
                // If session exists, ensure the signal ticket is up to date (mapping pending order ticket to active position ticket)
                ICXSignal* sig = existing.GetSignal();
                if(IS_VALID(sig) && sig.GetTicket() != ticket) {
                    // Only mark as LIMIT_FILL if the status is still pending (to prevent overwriting ENTRY_TE_REBOUND)
                    if(sig.GetStatus() < XE_EXECUTED) {
                        sig.SetTag("LIMIT_FILL");
                        sig.SetStatus(XE_EXECUTED);
                        sig.SetStatusMsg(StringFormat("Limit Fill Detected. Ticket:%I64u", ticket));
                        IRepository* repo = CX_GET_OBJ(m_ctx, "repo", IRepository);
                        if(IS_VALID(repo)) repo.UpdateStatus(sig);
                    }
                    sig.SetTicket(ticket);
                    XP_LOG_OK(xp, StringFormat("[POS-MANAGER-SCAN] Updated ticket for existing session. Ticket:%I64u, SID:%s", ticket, sid));
                }
            }
```

orgMgr에서 관리하는 ticket과 posMgr의 티켓을 연결하여 복잡하게 관리할 필요없음
orgMgr에서 트레일링 리바운드 포지션 진입 상황이면 대기 오더 제거하고 pos 진입까지만 정확하게 수행

포지션이 진입되면 그 포지션 자산을 assetMgr 검색하여 인지하는데 약간의 지연은 발생하지만 터미널에서 신규로 진입된 포지션을 펄스에서 정확하게 인식됨

약간의 시간지연은 발생하지만 posMgr가 적절하게 포지션을 인지하여 거래량 매칭 및 손절/익절 업데이트 수행.


---

## 3. Verification Plan

### Automated Verification
- Run `build_atse.ps1` to compile `ATS.mq5` and `ATSTestRunner.mq5`.
- Verify `0 errors, 0 warnings`.
- Run unit test suites to confirm no regressions.

### Manual Verification
- Deploy EA using `deploy_atse.ps1`.
- Verify entry logs to confirm the `"ENTRY_TE_REBOUND"` tag is correctly written to DB and expert logs.
- Verify limit fill cases to confirm `"LIMIT_FILL"` tag is correctly written to DB and expert logs.
