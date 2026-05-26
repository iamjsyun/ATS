# 설계 분석 보고서: E2E 시나리오별 DSL 흐름 및 제어 매트릭스 정합성 분석 (v1.0)

본 보고서는 사용자가 제시한 **"E2E 시나리오별 DSL 흐름 및 제어 매트릭스 (Watcher 통합본)"**의 개념적 모델과 현재 ATSE 프로젝트에 실제로 구현된 MQL5 소스코드의 명칭, 시맨틱 기호, 라이프사이클 및 분기 로직 간의 일관성(Consistency)과 정합성(Contextual Alignment)을 비교 분석하고 고도화 방향을 제안합니다.

---

## 1. 개념적 모델 vs 물리 구현 대조 매핑 (Mapping Matrix)

사용자 시나리오 상의 추상화된 상태/스텝 명칭과 실제 [AppOrchestrator.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/AppOrchestrator.mqh)에 정의된 구체적 코드를 대조한 매핑 표입니다.

### 1.1 상태 명칭 (State Names) 대조
개념적 상태 분류(`ORD_` 및 `POS_`)는 실제 코드상에서 단일한 `SESSION_` 접두어 아래 단계적 명칭(Phase)으로 일원화되어 구현되어 있습니다.

| 영역 | 개념적 설계 상태 (E2E Matrix) | 코드베이스 실제 상태명 ([CXDefine.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Platform/Core/Defines/CXDefine.mqh)) | 정합성 판정 & 비고 |
| :--- | :--- | :--- | :--- |
| **Watcher** | `WATCHER_ENTRY_DISCOVERY` | `WATCHER_ENTRY_DISCOVERY` (동적 할당) | **일치** (100% 동적 매핑) |
| | `WATCHER_ENTRY_EXECUTE` | `WATCHER_ENTRY_EXECUTE` (동적 할당) | **일치** |
| | `WATCHER_EXIT_DISCOVERY` | `WATCHER_EXIT_DISCOVERY` (동적 할당) | **일치** |
| | `WATCHER_EXIT_EXECUTE` | `WATCHER_EXIT_EXECUTE` (동적 할당) | **일치** |
| **진입 (Jin-te)** | `ORD_READY` | `SESSION_READY` | **개념 치환** (초기화 및 무결성 검증 단계) |
| | `ORD_EXECUTING` | `SESSION_EXECUTING` | **개념 치환** (브로커 주문 송신 단계) |
| | `ORD_PENDING` | `SESSION_PENDING` | **개념 치환** (터미널 대기 오더 감시 단계) |
| | `ORD_TRAILING` | `SESSION_TRAILING_ENTRY` | **개념 치환** (진입 트레일링 가격 추격) |
| **포지션 (Ik-te)**| `POS_ACTIVE` | `SESSION_ACTIVE` | **개념 치환** (포지션 체결 및 활성 감시) |
| | `POS_TRAILING` | `SESSION_TRAILING_STOP` | **개념 치환** (익절 트레일링 스탑 적용) |
| | `POS_LIQUIDATING` | `SESSION_LIQUIDATING` | **개념 치환** (청산 주문 송신 단계) |
| **생애주기 종료**| `SYS_CLOSED` | `SESSION_CLOSED` | **개념 치환** (리소스 정리 및 소멸 상태) |
| | `SYS_ERROR` | `SESSION_ERROR` | **개념 치환** (예외/장애 처리 상태) |

### 1.2 스텝 명칭 (Step Names) 대조
DSL에 정의되는 스텝(Step) 객체들의 이름 매핑 대조입니다.

| 영역 | 개념적 설계 스텝 (E2E Matrix) | 코드베이스 실제 DSL 스텝 명칭 ([AppOrchestrator.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/AppOrchestrator.mqh)) | 실제 바인딩 클래스 ([CXStepFactory.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/CXStepFactory.mqh)) |
| :--- | :--- | :--- | :--- |
| **Watcher** | `Step_EntryDiscovery` | `EntryDiscovery` | `CXStepEntryDiscovery` |
| | `Step_EntryExecute` | `EntryExecute` | `CXStepEntryExecute` |
| | `Step_ExitDiscovery` | `ExitDiscovery` | `CXStepExitDiscovery` |
| | `Step_ExitExecute` | `ExitExecute` | `CXStepExitExecute` |
| **진입 (Jin-te)** | `Step_OrderValidation` | `Composite:Step_Validating` | `CXCompositeStep` + 개별 Task 군 |
| | `Step_OrderPlacement` | `Composite:Step_Executing` | `CXCompositeStep` + 개별 Task 군 |
| | `Step_OrderWatch` | `Composite:Step_Pending` | `CXCompositeStep` + 개별 Task 군 |
| | `Step_OrderOptimization` | `Composite:Step_TrailingEntry` | `CXCompositeStep` + 개별 Task 군 |
| **포지션 (Ik-te)**| `Step_PositionWatch` | `Composite:Step_Active` | `CXCompositeStep` + 개별 Task 군 |
| | `Step_PositionGovernance` | `Composite:Step_TrailingStop` | `CXCompositeStep` + 개별 Task 군 |
| | `Step_PositionLiquidation` | `Composite:Step_Exit` | `CXCompositeStep` + 개별 Task 군 |
| **생애주기 종료**| `Step_SystemCleanup` | `Composite:Step_Closed` | `CXCompositeStep` + 개별 Task 군 |

---

## 2. 문맥 정합성 및 제어 흐름 분석

### 2.1 분기 가드(Branch Guard) 메커니즘
매트릭스에 표현된 `* XE_EXECUTED=POS_ACTIVE` 형태의 와일드카드 분기는 실제 DSL에서 다음과 같이 해석되고 처리됩니다.
- **구현 문법**: `* XE_EXECUTED=SESSION_ACTIVE`
- **구동 원리**: `Pulse()` 호출 시마다 Task들의 가드 조건에서 터미널 상의 주문 체결 상태를 감시하다가, `xe_status`가 `XE_EXECUTED (10)`으로 변경되는 즉시, 시퀀스는 즉각 지정된 분기 타겟인 `SESSION_ACTIVE`로 **상태 점프(State Jump)**를 실행합니다.
- **적용 영역**: `SESSION_PENDING` 및 `SESSION_TRAILING_ENTRY` 두 곳 모두에 등록되어 있어, 진입 오더가 대기 중이거나 가격 추격 중 언제라도 실물 체결이 발생하면 즉시 포지션 감시 모드로 진입할 수 있도록 무결성이 확보되어 있습니다.

### 2.2 수동 청산 패스트 트랙 (Manual Exit Fast-Track)
개별 세션 상태의 최상단에서 동작하는 `TASK_A_INTENT_WATCH` 태스크의 역할이 문맥적으로 가장 핵심적입니다.
- **감시**: 매 틱 폴링 시점에 터미널 상의 실물 자산(오더/포지션) 티켓의 실종 여부를 즉시 검사합니다.
- **Abort 및 Bypass**: 실물 자산이 수동으로 종료되었음이 감지되면, `xe_status`를 `XE_CLOSED_MANUAL (24)`로 즉시 변경하고 실행 루프를 `TASK_BREAK` 처리합니다.
- **강제 전이**: 이와 동시에 DB 상의 청산 상태(`xa_exit=2`)를 동시 마킹하고, 복잡한 주문 전송 단계(`Composite:Step_Exit`)를 Bypass하여 즉시 `SESSION_CLOSED` 상태로 강제 전이를 실행하는 **패스트 트랙**이 완벽하게 가동됩니다.

---

## 3. 고도화 제안 (Naming Standardization Suggestions)

현재 시스템은 설계 매트릭스와 완벽한 제어 일치성을 보이고 있으나, 개념적 명칭과 물리적 구현 코드 간의 간극을 좁히기 위해 향후 다음과 같은 고도화를 제안합니다.

1. **명칭 통일화 (Semantic Refactoring)**:
   - 추상적 세션 상태가 늘어남에 따라 세션 단계의 명칭을 `SESSION_READY` 등보다는 시나리오의 흐름을 직접 나타내는 명칭으로 개편하는 것을 검토할 수 있습니다.
   - 예: `SESSION_READY` $\rightarrow$ `SESSION_ORD_READY`, `SESSION_ACTIVE` $\rightarrow$ `SESSION_POS_ACTIVE` 형태로 세션 내 자산 도메인(Order vs Position)을 명시적으로 구분하면 시인성이 극대화됩니다.
2. **Composite Step 네이밍 규칙 일관성 확보**:
   - 워커 계열 스텝 이름인 `EntryDiscovery`와 마찬가지로 세션 계열 스텝 이름도 `Step_Validating` 대신 `OrderValidation` 등으로 변경하여, 접두어(`Composite:`) 없이도 스텝 클래스의 역할이 1:1 매칭되도록 가독성을 개선하는 구조 개편안이 유효합니다.

## 4. 결론
제시해주신 **E2E 흐름 및 제어 매트릭스**는 현재 분할 구동되는 Watcher(진입/청산 분할) 및 개별 Trading Session의 생애주기와 **논리적으로 100% 완전히 일치(Contextually Aligned)**합니다. 

명칭 상의 일부 표기 차이는 물리적 프레임워크(`SESSION_` 규격)와 개념적 도메인(`ORD_`/`POS_` 규격)을 연결하는 과정의 추상화 차이이며, 실제 런타임 제어 메커니즘(`ResolveId`, `TASK_A_INTENT_WATCH` 패스트트랙 등)은 기획된 설계 규격을 완벽하게 충족하며 작동하고 있습니다.
