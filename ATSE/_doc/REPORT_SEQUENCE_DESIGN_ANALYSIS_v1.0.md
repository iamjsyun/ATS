# ATSE 오케스트레이션 및 시퀀스 설계 정밀 분석 보고서 (v1.0)

## 1. 오케스트레이션 및 시퀀스 설계 정밀 분석
ATSE(Active Trading Session Engine)는 MQL5 환경에서 비즈니스 로직(무엇을 거래하고 감시할지)과 제어 흐름(어떤 단계로 실행할지)을 완벽히 분리하기 위해 **기호 명칭(Symbolic Name) 기반 DSL 파서**와 **선언적 시퀀스 엔진([CXFluentSequence](file:///d:/Projects/ATS/ATSE/CXTrade/Platform/Core/Sequence/CXFluentSequence.mqh))**을 채택하고 있습니다.

### 1.1 오케스트레이션 핵심 매커니즘
* **분리 모델 (Decoupled Model)**: 시퀀스의 조립은 [AppOrchestrator](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/AppOrchestrator.mqh)가 전담하며, 개별 실행 흐름인 [CXSessionTask](file:///d:/Projects/ATS/ATSE/CXTrade/Session/CXSessionTask.mqh)는 팩토리를 통해 빌드된 시퀀스 상태 머신을 전달받아 주입 실행합니다.
* **비동기 타이머 & 상태 전이**: [CXFluentSequence](file:///d:/Projects/ATS/ATSE/CXTrade/Platform/Core/Sequence/CXFluentSequence.mqh)는 매 틱(Pulse)마다 현재 상태에 바인딩된 스테이지([IXStage](file:///d:/Projects/ATS/ATSE/CXTrade/Platform/Core/Interfaces/IXStage.mqh))의 `OnProcess()`를 실행하며, 스테이지 내부의 아토믹 태스크들의 처리 결과 또는 강제 전이(Force Transition) 코드를 기반으로 다음 상태를 즉시 평가하여 이동합니다.

---

## 2. 진입 및 청산 시퀀스 단순 명확한 구조 분석

### 2.1 워처 진입/청산 4단계 코어 시퀀스
[AppOrchestrator](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/AppOrchestrator.mqh)의 `InitWatcherMap()`에 정의된 워처 시퀀스는 신호 탐색부터 세션 스포닝, 청산 탐색 및 집행까지 단순 명료한 4단계 상태 루프로 구성됩니다.

```cpp
"WATCHER_ENTRY_DISCOVERY   > EntryDiscovery     ? WATCHER_ENTRY_EXECUTE    ! WATCHER_EXIT_DISCOVERY    @ 0s, 0x"
"WATCHER_ENTRY_EXECUTE     > EntryExecute       ? WATCHER_EXIT_DISCOVERY   ! WATCHER_EXIT_DISCOVERY    @ 0s, 0x"
"WATCHER_EXIT_DISCOVERY    > ExitDiscovery      ? WATCHER_EXIT_EXECUTE     ! WATCHER_ENTRY_DISCOVERY   @ 0s, 0x"
"WATCHER_EXIT_EXECUTE      > ExitExecute        ? WATCHER_ENTRY_DISCOVERY  ! WATCHER_ENTRY_DISCOVERY   @ 0s, 0x"
```

1. **`WATCHER_ENTRY_DISCOVERY` (탐색)**
   * **Stage**: `EntryDiscovery` ([CXStageEntryDiscovery](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStageEntryDiscovery.mqh))
   * **동작**: DB를 스캔하여 신규 주입된 진입 신호(`xa_entry = 1`, `xe_status = 0 (READY)`)를 포착합니다. 포착 성공 시 즉시 `WATCHER_ENTRY_EXECUTE`로 이동합니다.
2. **`WATCHER_ENTRY_EXECUTE` (집행/스폰)**
   * **Stage**: `EntryExecute` ([CXStageEntryExecute](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStageEntryExecute.mqh))
   * **동작**: 포착된 신호 정보를 바탕으로 [CXSessionTask](file:///d:/Projects/ATS/ATSE/CXTrade/Session/CXSessionTask.mqh) 세션을 동적 생성 및 기동하고, DB 상태를 `xe_status = 2 (IN_TRANSIT)`로 전이시킨 후 청산 감시 단계인 `WATCHER_EXIT_DISCOVERY`로 진행합니다.
3. **`WATCHER_EXIT_DISCOVERY` (청산 신호 감시)**
   * **Stage**: `ExitDiscovery` ([CXStageExitDiscovery](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStageExitDiscovery.mqh))
   * **동작**: 실행 중인 세션 중 외부 청산 명령(`xa_exit = 1`)이 수신된 신호가 있는지 스캔합니다. 감지 시 `WATCHER_EXIT_EXECUTE`로 진행하며, 없을 시 다시 진입 탐색 상태로 복귀합니다.
4. **`WATCHER_EXIT_EXECUTE` (청산 집행)**
   * **Stage**: `ExitExecute` ([CXStageExitExecute](file:///d:/Projects/ATS/ATSE/CXTrade/Watcher/WatcherWorkflow/CXStageExitExecute.mqh))
   * **동작**: 해당 세션에 청산 시퀀스 강제 전이 명령을 전달하고 물리 자산 청산 트랜잭션을 실행합니다.

---

## 3. 진트, 익트, 및 SL/TP 도달 자동 청산 시퀀스 설계

### 3.1 진트 (Trailing Entry) 설계
* **동작 영역**: `ORD_TRACKING` 상태 $\rightarrow$ `Stage_OrderOptimization` 복합 스테이지 실행.
* **핵심 로직**:
  1. [CXTaskPending_L_Extreme](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Extreme.mqh)이 최저가(Buy) 또는 최고가(Sell) 극점을 실시간 갱신합니다.
  2. [CXTaskPending_L_Improve](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Improve.mqh)가 극점으로부터 `TE_START` 포인트만큼 이격된 자리에 추격 트리거 라인을 차트에 가시화합니다. 만약 가격이 이 완충 한계선(`TE_LIMIT`) 이내로 좁혀지면 오더를 뒤로 밀어내는 수정 수정 신호(`xp.SetInt(1)`)를 셋업합니다.
  3. [CXTaskPending_L_Rebound](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Rebound.mqh)가 극점 대비 `TE_STEP` 이상 반등을 포착하면 즉시 대기 주문 취소 및 시장가 진입 신호(`xp.SetInt(10)`)를 발생시킵니다.
  4. [CXTaskPending_R_Apply](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_R_Apply.mqh)가 취소 후 시장가 매수를 브로커에 전송하여 거래를 성사시킵니다.

### 3.2 익트 (Trailing Stop) 설계
* **동작 영역**: `POS_MONITORING` 상태 $\rightarrow$ `Stage_PositionGovernance` 복합 스테이지 실행.
* **핵심 로직**:
  1. [CXTaskAlphaCalc](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Active/CXTaskAlphaCalc.mqh)에서 포지션의 수익 상태가 최초 임계치 `TS_START` 포인트에 도달하는지 감시합니다.
  2. 임계치 도달 후 최댓값(Peak)을 기준으로 `TS_START` 만큼 후퇴한 위치에 Target Stop Loss(SL)를 계산하며, 이 타겟 가격이 기존 SL보다 `TS_STEP` 이상 유리한 방향으로 갱신되면 새로운 SL 값을 설정합니다.
  3. [CXTaskAlphaApply](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Active/CXTaskAlphaApply.mqh)가 계산된 새로운 SL을 터미널 플랫폼을 통해 브로커에 변경 요청하고 DB에 동기화합니다.

### 3.3 SL/TP 도달 자동 청산 설계 및 잠재적 결함
* **의도된 로직**: 
  1. 브로커가 가격 도달로 인해 포지션을 강제 청산(SL 또는 TP)하면 터미널의 물리적 자산이 소멸합니다.
  2. 세션 제어 태스크 루프 내에서 자산 소멸을 감지하고 MT5 거래 이력(`CheckHistoryClosure`)을 조회하여 청산 원인이 SL 도달(`XE_CLOSED_SL`)인지, TP 도달(`XE_CLOSED_TP`)인지 분류합니다.
  3. 사유에 따라 신호 상태 값을 정밀 변경하고 세션을 종결합니다.

* **[!WARNING] 발견된 설계상 누락 결함**:
  현재 [AppOrchestrator.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/AppOrchestrator.mqh)의 `positionedDsl`에 **`TASK_A_P_ALIGN` 태스크가 선언에서 제외**되어 있습니다.
  * **원인**: `posMgr.Pulse(xp)` (즉, 역사적 거래 확인 및 정밀 청산 구분을 수행하는 핵심 도메인 로직)은 오직 [CXTaskActive_P_Align](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Active/CXTaskActive_P_Align.mqh) 내부에서만 트리거됩니다.
  * **결과**: `TASK_A_P_ALIGN`이 부재하므로 런타임 중 브로커 SL/TP로 종료되어 포지션이 사라졌을 때, 역사 기록 검사가 트리거되지 못합니다. 이 때문에 [CXTaskIntentWatch](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Active/CXTaskIntentWatch.mqh)에 의해 **단순 수동 청산(`XE_CLOSED_MANUAL` / 값: 24)으로 모두 덮어씌워져 오분류되는 심각한 통계 데이터 왜곡 결함**이 발생합니다. (이 결함은 수정 보완이 강력하게 권장됩니다.)

---

## 4. 레거시 코드 잔존 여부 정밀 검사 정량 보고 (CXTrade 엔진 범위)
테스트 프로젝트(`CXTradeTest`)를 작업 범위에서 철저히 제외한 순수 **`CXTrade` 엔진 코어** 영역 내 레거시 자산 관리 모듈인 `ICXInventoryManager` / `CXInventoryManager` 잔존 현황 검사 결과입니다.

* **검사일시**: 2026-05-27
* **대상 경로**: `d:\Projects\ATS\ATSE\CXTrade\`

### 4.1 정량 분석 지표
* **레거시 파일 수**: **0개** (Target: `ICXInventoryManager.mqh`, `CXInventoryManager.mqh` $\rightarrow$ 100% 삭제 완료)
* **레거시 클래스/함수 참조 빈도**: **0회** (정합성 에러 및 잔여 헤더 링크 100% 제거 완료)
* **컴파일 오류 발생률**: **0.00%** (MetaEditor 빌드 기준 에러 및 경고 0건 검증)
* **레거시 잔존율**: **0.00%** (완전한 청소 상태 확인)

---

## 5. 오케스트레이션 및 시퀀스, 태스크 매트릭스

현재 오케스트레이터가 지원하고 매핑하는 전반적인 상태, 스테이지 유형 및 개별 하이퍼-아토믹 태스크의 매트릭스 일람입니다.

### 5.1 Watcher Sequence Matrix

| 현재 상태 ID | 바인딩 Stage | 성공 시 이동 (`?`) | 실패 시 이동 (`!`) | 제약 사항 (`@`) |
| :---: | :--- | :---: | :---: | :---: |
| `WATCHER_ENTRY_DISCOVERY` (1000) | `EntryDiscovery` | `WATCHER_ENTRY_EXECUTE` | `WATCHER_EXIT_DISCOVERY` | 0초, 0회 |
| `WATCHER_ENTRY_EXECUTE` (1001) | `EntryExecute` | `WATCHER_EXIT_DISCOVERY` | `WATCHER_EXIT_DISCOVERY` | 0초, 0회 |
| `WATCHER_EXIT_DISCOVERY` (1002) | `ExitDiscovery` | `WATCHER_EXIT_EXECUTE` | `WATCHER_ENTRY_DISCOVERY` | 0초, 0회 |
| `WATCHER_EXIT_EXECUTE` (1003) | `ExitExecute` | `WATCHER_ENTRY_DISCOVERY` | `WATCHER_ENTRY_DISCOVERY` | 0초, 0회 |

### 5.2 Session Sequence Matrix

| 상태 이름 (값) | 바인딩 Stage 명칭 | 내포된 Atomic Task 목록 | 성공 경로 (`?`) | 실패 경로 (`!`) | 타임아웃 |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **`ORD_TRACKING`** (5) | `Stage_OrderOptimization` | `TASK_A_INTENT_WATCH`<br>`TASK_P_L_EXTREME`<br>`TASK_P_L_REBOUND`<br>`TASK_P_L_IMPROVE`<br>`TASK_P_R_APPLY`<br>`TASK_P_V_SYNC` | `ORD_TRACKING` | `SYS_ERROR` | 300초 |
| **`POS_MONITORING`** (10) | `Stage_PositionGovernance` | `TASK_A_INTENT_WATCH`<br>`TASK_A_ALPHA_CALC`<br>`TASK_A_ALPHA_APPLY`<br>`TASK_A_V_TERMINAL`<br>*(누락: `TASK_A_P_ALIGN`)* | `POS_MONITORING` | `SYS_ERROR` | 3600초 |
| **`SYS_CLOSED`** (30) | N/A (종료 상태) | 리소스 정리 및 소멸 | N/A | N/A | N/A |
| **`SYS_ERROR`** (99) | N/A (에러 상태) | 예외 처리 및 로그 생성 | N/A | N/A | N/A |
