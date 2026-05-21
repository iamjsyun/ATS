# XTA 엔진 테스트 프로젝트(XTA.Test) 고도화 전략 보고서

**작성일**: 2026-05-17
**대상**: ATSA 단독 시뮬레이션 및 ATSE 연동 가상화 테스트 전략

---

## 1. 현재 테스트 프로젝트 진단 (Current State Analysis)

현재 `XTA.Test` 프로젝트의 `ScenarioRunner`와 `SimulationScenario.csv`는 지정된 시간(`@DelaySeconds`)에 따라 이벤트를 주입(`INJECT`)하고 DB 상태를 강제로 변경(`MOCK_EA`, `MOCK_APP`)하여 결과를 검증(`ASSERT`)하는 **시계열 기반(Time-Series) 시뮬레이션 구조**를 갖추고 있습니다.

**한계점**:
1.  **템플릿 다양성 부족**: 정상적인 Entry/Exit 템플릿만 제한적으로 지원하며 파싱 예외 상황 테스트가 부족합니다.
2.  **단방향 상태 주입**: `MOCK_EA`가 단순히 DB 값을 덮어쓰는 형태이며, ATSE의 복잡한 상태 전이(State Machine)를 모사하기엔 부족합니다.
3.  **예외 상황 커버리지**: 부분 체결(Partial Fill), 통신 지연, 3단계 청산 파이프라인 실패 등의 디테일한 연동 시나리오 검증이 누락되어 있습니다.

---

## 2. 템플릿 및 시나리오 CSV 고도화 전략 (Template & CSV Enhancement)

### 2.1. 템플릿(Template) 테스트 다각화
다양한 채널 환경과 예상치 못한 메시지 포맷에 대응하기 위해 템플릿 풀(Pool)을 고도화합니다.

*   **다중 템플릿 매핑**: `Template_Entry.txt` 외에도 `Template_Malformed.txt`, `Template_Missing_SL.txt`, `Template_Reverse_Order.txt` 등 다양한 변형 템플릿을 추가하여 파서(`XRuleInterpreter`)의 강건성을 테스트합니다.
*   **CSV 확장**: `SCENARIO_TYPE` 컬럼을 추가하여 주입할 템플릿의 종류를 명시적으로 지정할 수 있도록 개선합니다.

### 2.2. 시나리오 CSV 문법(Grammar) 확장
현재의 `TIMELINE_SEQUENCE` 액션을 더 세밀하게 제어할 수 있도록 문법을 고도화합니다.

*   **상태 대기 액션 추가**: 특정 시간 대기(`@N`) 뿐만 아니라, 특정 상태가 될 때까지 대기하는 `AWAIT_STATE:xe_status=10,timeout=5` 문법 도입.
*   **네거티브(Negative) 테스트 액션**: `ASSERT_REJECTED`, `ASSERT_ERROR` 등 실패를 기대하는 검증 문법 추가.

**고도화된 CSV 시나리오 예시**:
```csv
Scenario_ID,SCEN_TYPE,CNO,SNO,SYMBOL,DIR,LOT,PRICE,TIMELINE_SEQUENCE
SCEN_PARTIAL_FILL,ENTRY_NORMAL,1001,50,GOLD#,1,1.0,2350,INJECT@0 > AWAIT:xa_entry=1 > MOCK_EA:xe_status=10,lot=0.5@2 > ASSERT:lot=0.5@3
SCEN_PARSE_FAIL,ENTRY_MALFORMED,1001,51,GOLD#,1,0.0,0,INJECT@0 > ASSERT_NOT_EXISTS@2
```

---

## 3. ATSA 단독 가상 ATSE 연동 시뮬레이션 전략 (Virtual ATSE Simulation)

실제 MetaTrader 5(ATSE)를 실행하지 않고도 ATSA 내에서 완벽한 연동 테스트를 수행하기 위해 **가상 ATSE 엔진(Mock Engine)** 개념을 `ScenarioRunner`에 도입합니다.

### 시나리오 1: 3단계 청산 파이프라인 (3-Layer Liquidation) 검증
`spec.md`에 명시된 청산 파이프라인(ExitTicket -> ExitSweep -> ExitVerify)을 가상 엔진으로 테스트합니다.
*   **전략**: ATSA가 청산(`xa_exit=1`)을 요청할 때, `MOCK_EA`가 의도적으로 무시하거나 일시적 에러(`xe_status=99`)를 발생시킵니다.
*   **검증 포인트**: ATSA가 이를 감지하고 재시도 로직을 가동하여 끝내 청산을 완료(Archive)하는지 확인.

### 시나리오 2: 상태 기계(State Machine) 전이 오류 복구
*   **전략**: `MOCK_EA`가 허용되지 않는 상태 전이(예: `Ready(0)` -> `Closed(20)` 직행)를 DB에 강제 주입.
*   **검증 포인트**: ATSA의 `CXSignalWatcher` 또는 감시 로직이 이러한 이상 상태를 감지하고, 에러 로그를 남기거나 회로 차단기(Circuit Breaker)를 발동하는지 검증.

### 시나리오 3: 부분 체결 및 리쿼트 (Partial Fill & Re-quotes)
*   **전략**: 주입된 신호의 Lot이 `1.0`일 때, `MOCK_EA`가 체결 정보(`xe_status=10`)를 업데이트하면서 `lot=0.5`로 변경.
*   **검증 포인트**: ATSA UI 및 DataManager가 변경된 체결 수량을 올바르게 반영하고, 청산 시 남은 `0.5` Lot에 대해서만 청산 명령을 내리는지 검증.

### 시나리오 4: 통신 지연 및 좀비(Zombie) 신호 처리
*   **전략**: `INJECT` 후 `MOCK_EA`가 10분 이상 아무런 상태 응답(`xe_status`)을 주지 않는 상황을 시뮬레이션.
*   **검증 포인트**: 지정된 Timeout 이후 ATSA가 해당 신호를 '수동 개입 필요' 상태로 분류하거나 에러 처리(`xe_status=99`로 강제 변경)하는지 확인.

### 시나리오 5: 동시 다발적 신호 폭주 (Stress & Race Condition)
*   **전략**: 다수의 `INJECT`를 밀리초 단위로 동시에 발생시키고, `MOCK_EA`가 병렬로 상태를 업데이트하도록 CSV를 구성.
*   **검증 포인트**: `XIdManager`의 SID/GID 중복 방지 로직이 정상 작동하고, `ISignalRepository`에서 Lock 병목이나 데드락(Deadlock)이 발생하지 않는지 검증.

---

## 4. 실행 계획 (Next Implementation Steps)

1.  **ScenarioRunner.cs 리팩토링**: `MOCK_EA` 로직을 별도의 `VirtualAtseEngine` 클래스로 분리하여, 단순 값 덮어쓰기가 아닌 실제 ATSE와 유사한 지연 시간 및 상태 검증 로직을 포함하도록 개선.
2.  **CSV 파서 확장**: 새로운 문법(`AWAIT`, `ASSERT_FAIL`, 템플릿 선택 기능)을 파싱할 수 있도록 `ScenarioParser` 업데이트.
3.  **테스트 데이터셋 구축**: `_doc/TestTemplates/` 디렉토리를 생성하여 엣지 케이스용 텍스트 템플릿들을 보관하고 시나리오와 연동.