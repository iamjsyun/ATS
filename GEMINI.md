<!-- Import: C:\Users\hsnote\.gemini\extensions\oh-my-gemini-cli\GEMINI.md -->
## Cross-PC Synchronization & Modular Memory (v2.0)
- **Symbolic Link Mandate (Recommended)**: To ensure real-time synchronization of **Global Memory** and **Settings**, run the following in Administrator PowerShell:
  ```powershell
  Remove-Item -Path "$env:USERPROFILE\.gemini" -Recurse -Force
  New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.gemini" -Target "G:\내 드라이브\_Doc\gemini"
  ```
- **Project Memory Redirection (Fallback)**: If Admin rights are unavailable, all **Private Project Memory (Tier 3)** MUST be manually saved in `_doc/gemini/memory/ats/` (Cloud Linked) to ensure cross-PC consistency.
- **Custom Commands**: Project-wide CLI shortcuts are stored in `_doc/gemini/commands/`.

## Design Documentation Standard (v1.0)
- **PDCA/Design Storage**: 모든 설계 문서(.md)는 `_doc/` 폴더 최상위 또는 주제별 서브폴더에 저장하여 전 프로젝트가 공유한다.
- **Version Control**: 문서 파일명에는 반드시 `v1.x` 형태의 버전을 포함한다.

## Simulator Shared Memory
- **Simulator Target**: ATSE의 하이퍼-원자적 태스크 무결성 검증.
- **Core Principle**: Step-Lock 기반 Virtual Clock 시스템 (결정성 보장).
- **Data Source**: SQLite 역주입 및 CSV 시나리오 연동.

## Trading Logging Standard (v10.4 - Mandatory)
모든 트레이딩 함수 호출 시 다음의 로깅 프리픽스와 형식을 엄격히 준수해야 한다. 모든 로그는 시스템 로그(Experts/Global)와 개별 세션 로그(File/Remote)에 동시에 기록되어야 한다.

1.  **주문 진입 (OrderOpen)**
    - **성공 로그**: `[EXEC-ENTRY] Sending Order: [Sym:{symbol}, Type:{type}, Lot:{lot}, Price:{price}, SL:{sl}, TP:{tp}, Mkt:{marketPrice}, TELimPts:{teLimPts}, TELimP:{teLimPrice}, TESta:{teStart}, TESte:{teStep}, SID:{sid}]`
    - **실패 로그**: `[EXEC-ENTRY-FAIL] Broker Code:{ret_code}({description}), SysErr:{err}. Original Params: [Sym:{symbol}, Type:{type}, Lot:{lot}, P:{price}, SL:{sl}, TP:{tp}, SID:{sid}]`

2.  **주문 수정 (OrderModify)**
    - **성공 로그**: `[ORDER-MODIFY] Sending Request: [Ticket:{ticket}, Price:{price}, SL:{sl}, TP:{tp}]`
    - **실패 로그**: `[ORDER-MODIFY-FAIL] Broker Code:{ret_code}({description}), SysErr:{err}. Original Params: [Ticket:{ticket}, Price:{price}, SL:{sl}, TP:{tp}]`

3.  **포지션 수정 (PositionModify)**
    - **성공 로그**: `[POS-MODIFY] Sending Request: [Ticket:{ticket}, SL:{sl}, TP:{tp}]`
    - **실패 로그**: `[POS-MODIFY-FAIL] Broker Code:{ret_code}({description}), SysErr:{err}. Original Params: [Ticket:{ticket}, SL:{sl}, TP:{tp}]`

4.  **주문 삭제 (OrderDelete)**
    - **성공 로그**: `[ORDER-DELETE] Sending Request: [Ticket:{ticket}]`
    - **실패 로그**: `[ORDER-DELETE-FAIL] Broker Code:{ret_code}({description}), SysErr:{err}. Original Params: [Ticket:{ticket}]`

## Trading Process Standard (v11.0 - Mandatory)
모든 트레이딩 신호 처리 및 감시 작업은 다음의 재설계된 규칙을 엄격히 준수해야 한다.

### 1. 신호 타입 1 (지정가/Pending) 처리 규칙
1.  **신호가 무시**: 신호에 주입된 원본 가격(`price_signal`)은 무조건 무시한다. (0 또는 임의의 값이라도 상관없음)
2.  **시장가 기준 오더가 결정**: 신호 감지 시점의 실시간 시장가(Ask/Bid)에 `limit_offset`을 적용하여 실제 주문 가격(`execPrice`)을 결정한다.
3.  **실행가 기준 SL/TP 산출**: 위에서 결정된 `execPrice`를 기준으로 `sl`, `tp` 포인트를 가격으로 환산하여 적용한다. (Invalid Stops 원천 차단)
4.  **로트(Lot) 검증**: 신호의 로트값을 그대로 사용하되, `lot <= 0` 또는 `lot > 50`인 경우 치명적 에러로 처리한다.
5.  **메타데이터 대입**: `Expert Magic Number`와 `Comment(SID)`를 반드시 모든 주문 요청에 포함한다.
6.  **포인트 기반 변환**: 가격과 로트를 제외한 모든 트레이딩 옵션(SL, TP, TE, TS 등)은 정수 형태의 포인트값으로 취급하며, 계산 시에만 가격으로 변환한다.

### 2. 로깅 및 사후 검증 규칙 (Execution & Verify)
1.  **전역 파라미터 로깅**: 모든 트레이딩 함수(`m_trade`) 호출 시, 함수 인자 전체와 `te_limit`, `te_start`, `te_step`, `sl`, `tp`, `ticket`을 포함한 상세 로그를 기록한다.
2.  **결과 로깅**: 브로커 리턴 코드(`ret_code`)와 응답 메시지를 반드시 기록한다.
3.  **물리적 자산 재검색**: 함수 호출 직후, 터미널의 포지션/주문 리스트를 재검색하여 실물 자산 존재 여부를 확인하고 그 결과를 로그에 남긴다. 이때 검색 조건으로 사용한 모든 값들을 로그에 포함한다.

### 3. SignalWatcher 감시 및 필터링 규칙
1.  **검증 실패 로그 상세화**: `Validate` 과정 실패 시, 해당 신호의 모든 필드(`sid`, `symbol`, `price`, `lot`, `lot_type`, `te`, `ts`, `sl`, `tp`, `xa_entry`, `xa_exit`, `xe_status`)를 상세히 기록한다.
2.  **무신호 로그 억제**: `Pulse` 중 신호가 감지되지 않으면 불필요한 "No signal" 로그 기록을 중지한다.
3.  **중복 로그 차단**: 신호 감지 후 상태가 변경되기 전까지 동일한 내용의 반복 로그 출력을 금지한다. (Spam 방지)

## Encoding Policy
- **MQL5 Source Files**: All `.mqh` and `.mq5` files must be managed using UTF-8 encoding (BOM or No-BOM) to ensure consistent character representation and prevent corruption.

    - `g:` -> `G:\내 드라이브\` (Google Drive Shared Folder)
    - 공용 문서 폴더 -> `G:\내 드라이브\_Doc\`
- **Automatic Synchronization**: All `GEMINI.md` and private `MEMORY.md` files are automatically synchronized with the G: drive shared workspace for cross-environment persistence.
- **Partial Class Strategy**: Refactoring FluentSeq services into `partial class` files (`.Sequence.cs`, `.Methods.cs`) is approved for AI-optimized context management.

## Testing Policy
- **XTA.Test Execution**: Do not execute the `XTA.Test` project automatically during implementation turns. Execute tests only when explicitly requested by the user.

## Architectural Mandates
- **ID Governance**: All SID/GID generation must delegate to `XIdManager` (v8.2 Standard).
    - **SID Format**: `CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1)` (Total 23 chars, including hyphens).
    - **GID Format**: `CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)` (Total 19 chars).
- **Communication Protocol**: Follow the v7.9 Archival Protocol (`xa_exit=3` for transfer).
- **Market-Price Priority Mandate (v10.23)**: All price-related tasks (Entry, SL/TP, Trailing) MUST use real-time Market Price (Ask/Bid) as the baseline for point-to-price conversions, ignoring stale signal prices (`price_signal`).
- **DataManager State Transition Matrix (v9.8.11)**:
    - **신규 주입 (Save)**: `xa_entry=1`, `xa_exit=0`, `xe_status=0 (READY)`
    - **청산 요청 (Exit)**: `xa_exit=1 (ACTIVE)` (EA 청산 실행 대상)
    - **청산 완료 (Comp)**: `xa_exit=2 (COMP)`, `xe_status=20 (CLOSED)`
    - **이관 대기 (Arch)**: `xa_exit=3 (ARCH)` (DB 이관 대기 대상)

## DataManager UI/UX Standards (v8.8 - Critical)
- **XAML Binding Convention**: All editor fields in `DataManagerView.xaml` MUST use lowercase property names matching the `XSignal` model (e.g., `cno`, `sno`, `symbol`, `lot`, `tp`, `sl`). Do NOT use PascalCase for these bindings.
- **Initialization Sequence**: `DataManagerViewModel` must explicitly set model fields to the 0th index of available lists (CnoList, SnoList, etc.) during construction or reset.
- UI Synchronization: After any batch update to `SelectedSignal`, `RefreshAll()` (which triggers `RaisePropertyChanged(null)`) must be called to force WPF to re-read all bound values.
- **Persistence**: These rules ensure ComboBoxes default to index 0 on startup and preserve selections during "New Signal" operations.

## WPF Navigation Standards (v9.0)
- **Pattern**: All primary UI navigation MUST use **Dynamic View Switching (View-Model First)**.
- **Mechanism**: Transitions are handled by swapping the `CurrentView` property in `MainViewModel`.
- **Rendering**: `MainWindow.xaml` uses `DataTemplate` definitions in its Resources to map ViewModel types to their corresponding UserControl Views.
- **Prohibition**: Do NOT use standalone popup windows (`Window.Show()`) for main application features (Dashboard, DataManager, Settings). All such features must be implemented as `UserControl` Views integrated into the main frame.

## Configuration Management (v9.0)
- **Centralized Source**: All system, engine, and channel settings MUST reside in `_config\ATSA.json`. (Redundant sections like `SystemSettings` are integrated into `System`).
- **Custom Configuration Path**: The system supports specifying a custom configuration file path via the `-config` command-line argument (e.g., `ATSA.exe -config C:\Path\To\MyConfig.json`).
- **Prohibition**: Redundant configuration files (e.g., `XConfig.json`) are strictly prohibited.
- **Explicit Full-Path Mandate**: The `DatabaseFullPath` property in `ATSA.json` SHOULD contain the absolute path to the MetaTrader 5 Common Files folder for maximum visibility.
- **Auto-Generation**: The system automatically generates `ATSA.json` with the current user's MT5 common path if missing.
- **Reference Standard**: All modules MUST use `XConfig.GetConfigPath()` to access the unified settings.

## UCXSignalView UI Standard (v9.6)
- **Layout Architecture**: Strictly follow a **Two-Line Card-Hybrid** design.
- **Directional Marker**: Far-left 4px vertical line indicates direction (BUY: `#2196F3` Blue, SELL: `#F44336` Red).
- **Line 1 (Trading Data)**: SID, Symbol, Dir, Type, Price, LotT, Lot, TE, TS, SL, TP, XA:EN, XA:EX.
- **Line 2 (Execution Details)**: Status Badge (`Code:Name`) + `┗` Link + Full-width `xe_status_msg`.
- **Numeric Formatting**:
    - `price`, `lot`: Standardized to `0.00` (N2 format).
    - `te_start`, `ts_start`, `sl`, `tp`: Standardized to **Integer** (N0 format).
    - All numeric fields MUST be **Right-Aligned** with a small right margin (4-6px).
- **Descriptive Displays**: `Dir`, `LotT`, `XA:EN`, `XA:EX`, and `Status` MUST show the combined "Code:Name" format (e.g., `10:EXECUTED`).
- **Aesthetics**: Each row is an independent card with subtle margins, `CornerRadius="3"`, and no grid lines.
