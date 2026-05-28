# REPORT: Naming Convention Consistency Review & Standardization (v1.0)

This report evaluates the naming conventions of stages and task classes in the ATSE MQL5 project, identifies structural inconsistencies, and proposes a standardized naming specification to align with the L-P-R-V-P architectural design.

---

## 1. Current Class and File Naming Analysis

A review of the active workflows in the MQL5 codebase reveals naming deviations across different lifecycle stages.

### A. Discovery Stage (Watcher)
- **Current Naming**: `CXStageEntryDiscovery`, `CXStageExitDiscovery`, `CXStageEntryExecute`, `CXStageExitExecute`.
- **Inconsistency**: In the lifecycle matrix report, these were historically referred to as `CXStepDiscovery`, creating a discrepancy between documentation and implementation files.

### B. Pending Stage (StageEntryExecute)
- **Current Naming**:
  - `CXTaskPending_V_Sync.mqh` (Verify)
  - `CXTaskPending_L_Extreme.mqh` (Logic)
  - `CXTaskPending_L_Improve.mqh` (Logic)
  - `CXTaskPending_L_Rebound.mqh` (Logic)
  - `CXTaskPending_R_Apply.mqh` (Request)
- **Evaluation**: **Excellent Consistency**. Follows the strict `CXTask{Stage}_{Phase}_{Name}` prefix structure.

### C. Active Stage (StageActiveExecute)
- **Current Naming**:
  - `CXTaskActive_TS_TriggerWatch.mqh` (Missing Phase Prefix)
  - `CXTaskAlphaCalc.mqh` (Missing `Active` Stage & Phase Prefix)
  - `CXTaskAlphaApply.mqh` (Missing `Active` Stage & Phase Prefix)
  - `CXTaskActive_Closed.mqh` (Missing Phase Prefix)
- **Evaluation**: **High Inconsistency**. The active stage tasks bypass standard stage prefixes and phase codes (`V` / `L` / `R` / `P`), breaking the unified architecture.

### D. Exit Stage (StageExitExecute)
- **Current Naming**:
  - `CXTaskExit_L_Prepare.mqh`
  - `CXTaskExit_P_Lock.mqh`
  - `CXTaskExit_R_Order.mqh`
  - `CXTaskExit_V_Terminal.mqh`
  - `CXTaskExit_P_Finalize.mqh`
- **Evaluation**: **Excellent Consistency**. Strictly adheres to the standard pattern.

---

## 2. Proposed Naming Standards

To ensure readability and structural consistency, the following naming standard is defined for all execution tasks:

$$\text{Class Name} = \text{CXTask} + \text{Stage} + \text{\_} + \text{Phase} + \text{\_} + \text{Name}$$

### Phase Codes:
- **`V` (Verify)**: System / Terminal state validation.
- **`L` (Logic)**: Strategy calculations, indicators, and price thresholds.
- **`R` (Request)**: Broker order transactions (open, close, modify).
- **`P` (Process)**: Context management, event handling, and pipeline finalizations.

---

## 3. Standardization Target Matrix (Active Stage Refactoring)

| Current Filename / Class | Standardized Filename / Class | Rationale |
| :--- | :--- | :--- |
| `CXTaskActive_TS_TriggerWatch` | `CXTaskActive_L_TS_TriggerWatch` | Belongs to **Logic (L)** phase tracking threshold profit. |
| `CXTaskAlphaCalc` | `CXTaskActive_L_AlphaCalc` | Standardizes prefix and places calculations in **Logic (L)**. |
| `CXTaskAlphaApply` | `CXTaskActive_R_AlphaApply` | Handles the SL/TP broker modifications in **Request (R)**. |
| `CXTaskActive_Closed` | `CXTaskActive_P_Closed` | Handles session context cleanup under **Process (P)**. |

---

## 4. Implementation Steps

1. **Step 1**: Rename the physical files in `d:\Projects\ATS\ATSE\CXTrade\Session\Workflow\Active\`.
2. **Step 2**: Update the internal MQL5 `class` declarations inside the renamed files.
3. **Step 3**: Re-bind the renamed tasks in the session orchestrator/factory (`CXTaskFactory.mqh`).
4. **Step 4**: Update reference lists in project documentation.
