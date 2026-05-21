# ATSA Project Directive
<!-- Import: D:\Projects\ATS\GEMINI.md -->

## Mandate
This agent is the **Orchestrator**.

## Constraints
- **UI Standard**: DataManagerView.xaml bindings MUST be lowercase (e.g., `cno`, `sno`, `sid`).
- **Navigation**: Use Dynamic View Switching (View-Model First). NO popup windows.
- Config: ATSA owns `_config/ATSA.json` (Relative to Executable path). Source-level `_config` is prohibited.
- **Scope**: ATSA.YouTube (ay) project is EXCLUDED from modifications until explicitly requested.
- **Governance**: SID/GID creation MUST delegate to `XIdManager`.

## Responsibilities
- UI/UX implementation.
- Telegram Gateway logic.
- System-wide configuration management.

## Sequence Design Standards (v9.7)
- **SRP Mandate**: All sequences (FluentSeq) MUST be decomposed into atomic tasks where **1 Task = 1 Responsibility**.
- **Task Granularity**: Decompose complex logic into: Recognition, Validation, Persistence, Execution, and Notification tasks.
- **Independence**: Each task must be executable in isolation with minimal side effects outside its stated responsibility.

## Asset Integrity Policy (Mandatory)
- **Template/Keyword Modification**: Unauthorized modification of channel-specific templates (`Template_*.txt`) and keyword files (`Keywords.txt`, `Keywords.json`) is strictly prohibited.
- **Change Procedure**: Any changes to these files MUST be requested via explicit user directive and verified against system logic (e.g., exit detection sensitivity) before execution.

## Configuration Standards (v9.5)
- **Architecture**: Unified Channel-Centric design. Root-level `YouTubeRoi` is prohibited.
- **YouTube Integration**: `YouTubeUrl` and `YouTubeROI` (CSV: "X,Y,W,H") MUST reside within `XChannelConfig`.
- **Entry Defaults**: Standardized Trailing Entry parameters: `TeStart=500`, `TeStep=100`, `TeLimit=1000`.
- **Lot Strategy**: `XLotStrategy` MUST explicitly initialize `Rate` (default: 0) alongside `Value`.
- **Interpreter Mapping**: Channels use an explicit `Interpreter` property (e.g., "GlobalGold", "GMK") to define logic, regardless of CNO/CID.
- **Original Source IDs**:
    - **GlobalGold**: `-1002204600811` (CNO 1001)
    - **GMK**: `-1002218781954` (CNO 1002)
    - **XHANA**: `-1003778889507` (CNO 3001)
    - **XDUNA**: `-1003697953708` (CNO 3002)
- **Zero Matching**: Fuzzy CID matching and CID-to-CNO mapping are deprecated. 1:1 ID-to-CNO mapping is enforced.

