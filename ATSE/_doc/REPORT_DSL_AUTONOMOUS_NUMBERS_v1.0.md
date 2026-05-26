# 설계 보고서: 상태 관리 규격(xa_entry/xa_exit/xe_status) 준수 기반 DSL 동적 번호 자동 부여 설계 (v1.0)

본 보고서는 `xa_entry`, `xa_exit`, `xe_status` 3대 상태 파라미터의 관리 전략 규격을 준수함으로써, DSL에 사용되는 모든 제어 흐름용 문자열에 대해 개발자가 명시적인 상수 등록을 전면 생략하고 엔진 자체적으로 숫자를 부여하여 안전하게 구동하는 설계 방안을 기술합니다.

---

## 1. 핵심 아키텍처 원칙 (Decoupling Principal)
이 설계의 근본적인 타당성은 **"내부 실행 상태"**와 **"외부 저장/보고 상태"**의 완전한 디커플링(Decoupling)에 있습니다.

```
       [ ATSE Sandbox (Memory Only) ]           [ Shared Layer (DB & ATSA UI) ]
 ┌─────────────────────────────────────────┐     ┌────────────────────────────┐
 │  DSL States (Dynamic Auto-IDs 1000+)    │     │  Physical Schema Columns   │
 │                                         │     │                            │
 │  "SESSION_VALIDATING"       --> 1000    │     │  - xa_entry  (0 or 1)      │
 │  "SESSION_TRAILING_ENTRY"   --> 1001    │────>│  - xa_exit   (0, 1, 2, 3)  │
 │  "WATCHER_ENTRY_DISCOVERY"  --> 1002    │     │  - xe_status (0, 5, 10, 20)│
 │                                         │     │                            │
 └─────────────────────────────────────────┘     └────────────────────────────┘
```

1. **내부 제어 상태 (Internal DSL States)**:
   - `SESSION_VALIDATING`, `SESSION_TRAILING_ENTRY`, `WATCHER_ENTRY_DISCOVERY` 등은 오직 ATSE 내부 시퀀스 엔진이 다음 실행할 Step을 결정하고 트레일링 등의 루프를 돌기 위한 **메모리상의 흐름 제어 변수**입니다.
2. **외부 연동 상태 (Externalized System States)**:
   - `xa_entry`, `xa_exit`, `xe_status`는 SQLite DB 스키마에 저장되고 ATSA(WPF 매니저) 프로그램이 조회하여 UI 화면에 표시하는 **영속 데이터 표준 상태**입니다.

---

## 2. 동적 자체 숫자 부여의 타당성 및 작동 메커니즘

### 2.1 데이터베이스 경계 규격 격리 (Database Boundary Isolation)
데이터베이스의 `signals` 테이블 설계 스키마인 [CXSignalSchema.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Platform/Core/Interfaces/CXSignalSchema.mqh) 필드를 보면, 내부 시퀀스 흐름 상태(예: `SESSION_STATE` 등)를 보관하는 컬럼은 존재하지 않습니다.

오직 표준화된 상태 전이 매트릭스(DataManager State Transition Matrix v9.8.11)의 값들만 반영됩니다:
- `xa_entry`: `0 (RAW)`, `1 (ACTIVE)`
- `xa_exit`: `0 (RAW)`, `1 (ACTIVE)`, `2 (COMP)`, `3 (ARCH)`
- `xe_status`: `0 (READY)`, `5 (PENDING_PLACED)`, `10 (EXECUTED)`, `20 (CLOSED_SIGNAL)`, `21 (CLOSED_SL)`, `22 (CLOSED_TP)`, `24 (CLOSED_MANUAL)`, `99 (ERROR)`

따라서, 내부 제어용 문자열들이 어떤 정수 ID값(예: `1000`, `1001`, `1002`)으로 매핑되든, DB 저장 데이터 및 외부 프로그램과의 정합성에는 아무런 영향이 없습니다.

### 2.2 전이 경계에서의 DB 상태 동기화 (Transition Boundary Sync)
내부 DSL 시퀀스 상태가 전이되는 와중에 데이터베이스로의 물리적 동기화가 필요한 특정 경계 시점(예: 진입 완료, 청산 등)에는, 실행 중인 Step 클래스 내에서 다음과 같이 명시적 정수 Enum 상수 규격을 사용하여 DB 상태를 갱신합니다.

```mql5
// [v11.3] 진입 오더가 실제로 terminal에 접수 완료된 시점 (Boundary Transition)
sig.SetStatus(XE_PENDING_PLACED); // 5 (Standard Enum Value)
sig.SetXAEntry(XA_ACTIVE);         // 1
m_repo.UpdateStatus(sig);          // DB signals 테이블에 5와 1로 업데이트
```

이 시점에서 쓰이는 `XE_PENDING_PLACED`나 `XA_ACTIVE`는 MQL5 표준 Enum(`CXDefine.mqh`)에 정의된 고정 정수형 상수이므로, DSL 문자열 해석기와 결합되어 있지 않습니다. 즉, DSL 내부 상태명들의 숫자 값은 자유롭게 자동 생성(Auto-assigned)되어도 안전합니다.

---

## 3. 동적 자동 매핑 설계 구현 시나리오

만약 하드코딩 매핑 코드를 완전히 제거할 경우, 빌드와 전이 동작은 다음과 같은 흐름으로 통제됩니다.

### 1) Orchestrator 초기화부 제거
[AppOrchestrator.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/App/Orchestration/AppOrchestrator.mqh)의 `RegisterStandardNames` 내 모든 `SESSION_xxx` 및 `WATCHER_xxx` 레지스트리 추가 코드를 안전하게 삭제합니다.
```mql5
virtual void RegisterStandardNames() override {
    // 내부 제어 문자열 매핑을 전부 지우고 비워둠 (동적 할당기 위임)
}
```

### 2) DSL 문자열 로딩 시 자체 자동 번호 매핑
오케스트레이터 기동 시 `BuildFromDSL`을 통해 DSL 배열이 분석될 때, `m_auto_id_counter`가 `1000`부터 순차적으로 정수값을 할당해 갑니다:
- `"SESSION_READY"` $\rightarrow$ `1000`
- `"SESSION_VALIDATING"` $\rightarrow$ `1001`
- `"SESSION_EXECUTING"` $\rightarrow$ `1002`
- `"SESSION_PENDING"` $\rightarrow$ `1003`

### 3) Step의 전이 목적지 런타임 해석
시퀀스가 작동하는 과정에서 전이가 이루어질 때, Step 실행 결과로 `"SESSION_ACTIVE"` 문자열을 리턴하면, 실행기 내부에서 `ResolveId("SESSION_ACTIVE")`를 수행하여 동적으로 생성되었던 고유 ID를 조회하고, 이에 해당하는 다음 Step으로 정상 전이합니다.

---

## 4. 아키텍처 규칙 및 결론

1. **전략 규격의 엄격한 준수**:
   - `xa_entry`, `xa_exit`, `xe_status`를 업데이트하는 시점(경계 전이)에는 반드시 `CXDefine.mqh`에 고정된 표준 Enum 값들을 소스코드 상에 명시적으로 사용해야 합니다.
2. **DSL 상수 정의 생략 보장**:
   - 1번의 DB 바운더리 규격만 충족하면, DSL 상에서 사용되는 모든 흐름 제어용 문자열들은 레지스트리에 수동으로 상수를 등록할 필요가 없습니다. 
   - `m_auto_id_counter` 엔진에 번호 부여 권한을 완전히 위임하여 **완벽한 선언적 DSL 시퀀스 제어 환경**을 완성할 수 있습니다.
