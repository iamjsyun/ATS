# ATSE Log Optimization & Backtrace Strategy Report (v1.0)

## 1. 개요 (Executive Summary)
현재 ATSE (Active Trading State Engine)는 안정적인 인프라 구축 및 검증 단계를 지나 실제 운용 단계에 진입함에 따라, **매 틱마다 반복적으로 호출되는 상태 폴링(Polling) 및 모니터링 성격의 로그가 로그 용량을 크게 증가시키고 중요 트랜잭션의 가독성을 저해하는 문제**를 안고 있다.

본 설계 보고서는 기존 로그 관리 클래스(`CXAuditFormatter`, `ICXLogger` 등)의 코어 인터페이스를 그대로 유지하면서:
1. 불필요한 반복 틱(Trace/Debug) 로그를 완전히 걷어내는 **로그 다이어트(Log Reduction)**
2. 에러 및 중요 이벤트 발생 시 해당 소스 코드의 위치(파일명, 라인 번호, 함수명)를 즉시 추적할 수 있도록 돕는 **무결성 역추적(Backtrace Context) 자동 삽입 설계**

를 달성하기 위한 정밀 아키텍처 전략을 제시한다.

---

## 2. 로그 다이어트 전략 (Log Reduction)

동작 무결성이 확보되었으므로, 매 틱(Tick) 단위로 출력되어 디스크 I/O를 유발하는 폴링 성격의 메시지를 대폭 제거(De-noise)하고, 오직 상태 전이에 직접적 영향을 미치는 핵심 이벤트에 대해서만 로그를 남긴다.

### 2.1. 제거 대상 (De-noise Targets)
매 주기(Loop/Tick)마다 출력되는 다음 로그들은 완전 제거하거나 디버그 컴파일러 지시자(`DEBUG_MODE`) 하에서만 컴파일되도록 제한한다.

| 소스 파일 | 라인 수준 | 제거 대상 로그 메시지 및 사유 |
| :--- | :---: | :--- |
| `CXStepDiscovery.mqh` | TRACE | `[WATCHER-DISCOVERY] Engine Pulsing: Listening for signals...` (무의미한 틱 루프 로그) |
| `CXTaskPending_V_Sync.mqh` | TRACE | `Monitoring State` / `Yield: No ticket yet` (체결 대기 중 매 틱 출력 차단) |
| `CXTaskPending_V_Terminal.mqh` | TRACE/WARN | `OK: Order {ID} found` / `WAIT: Order {ID} not yet visible` (터미널 오더 검색 폴링 로그) |
| `CXTaskExit_V_Terminal.mqh` | TRACE/DEBUG | `Monitoring Liquidation...` / `Yield: Asset still active` (청산 확인 대기 폴링 로그) |
| `CXTaskPending_L_Extreme.mqh` | TRACE | `New Extreme Tracked: {Price}` (단순 고/저점 갱신 시마다 출력되는 대량의 트레일링 로그) |

### 2.2. 유지 및 고도화 대상 (Core Transaction Events)
신호의 라이프사이클에 결정적 전이를 가져오는 트랜잭션성 로그는 엄격히 유지하되, **Backtrace Context**를 탑재하여 중요도를 높인다.

1. **Watcher & Spawner**:
   * 신규 신호 최초 감지 성공/실패 (`[WATCHER-VALIDATION]`)
   * 신규 세션 생성 성공/실패 (`[WATCHER-SPAWN] SUCCESS / FAILED`)
2. **Order Execution (Entry)**:
   * 주문 전송 시도 로그 (`[EXEC-ENTRY]`) 및 브로커 리턴 실패 로그 (`[EXEC-ENTRY-FAIL]`)
   * 주문 성공 후 발급된 티켓 매핑 완료 로그
3. **Trailing & Modification**:
   * 진입가 개선 적용 성공/실패 (`[PEND-R-APPLY] SUCCESS / FAILED`)
   * 포지션 트레일링 스탑 발동 및 SL 개선 수정 (`[POS-MODIFY] SUCCESS / FAILED`)
4. **Liquidation (Exit)**:
   * DB 청산 의도 발견 및 청산 프로세스 시작 (`[PENDING-V-SYNC] Exit command detected`)
   * 물리적 소멸 및 잔여 오더 정리 완료 (`[EXIT-V-TERM] SUCCESS`)
   * 세션 최종 소멸 및 DB 마킹 완료 (`xe_status=20, xa_exit=2`)

---

## 3. 무결성 역추적 설계 (E2E Error Backtrace Design)

기존 로깅 코드의 형식을 복잡하게 만들지 않고, 에러 발생 시 소스 코드 상의 정확한 지점을 추적할 수 있도록 **MQL5 전처리 매크로**를 활용하여 로깅 매크로 단에서 소스 위치를 자동으로 추출하여 메시지에 접합하도록 아키텍처를 개선한다.

### 3.1. MQL5 내장 매크로 활용
* `__FILE__`: 컴파일 타임의 현재 소스 파일 절대/상대 경로.
* `__LINE__`: 해당 매크로가 호출된 소스 코드 상의 라인 번호.
* `__FUNCTION__`: 해당 매크로를 실행 중인 스코프의 함수/메서드명.

### 3.2. 매크로 레이어 확장 설계 (`CXMacros.mqh` 개선안)
기존 `XP_LOG_ERROR` 및 `XP_LOG_WARN` 매크로 내부에서 `__FILE__`, `__LINE__`, `__FUNCTION__` 정보를 자동으로 가로채 메시지 본문 앞머리에 주입하도록 확장한다.

```mql5
//--- 수정 전 (기존 매크로)
#define XP_LOG_ERROR(xp, msg) { \
    ICXLogger* _log = GetLoggerSafe(xp, LOG_LVL_ERROR, false); \
    if(IS_VALID(_log)) _log.Error(xp, msg, LOG_POLICY_ALWAYS); \
}

//--- 수정 후 (Backtrace 자동 수집 매크로 설계)
#define XP_LOG_ERROR(xp, msg) { \
    ICXLogger* _log = GetLoggerSafe(xp, LOG_LVL_ERROR, false); \
    if(IS_VALID(_log)) { \
        string traceInfo = StringFormat("[%s:%d in %s]", __FILE__, __LINE__, __FUNCTION__); \
        _log.Error(xp, traceInfo + " " + msg, LOG_POLICY_ALWAYS); \
    } \
}

#define XP_LOG_WARN(xp, msg) { \
    ICXLogger* _log = GetLoggerSafe(xp, LOG_LVL_WARN, false); \
    if(IS_VALID(_log)) { \
        string traceInfo = StringFormat("[%s:%d in %s]", __FILE__, __LINE__, __FUNCTION__); \
        _log.Warn(xp, traceInfo + " " + msg, LOG_POLICY_ON_CHANGE); \
    } \
}
```

* **효과**: 태스크 소스 코드 내에서는 기존과 동일하게 `XP_LOG_ERROR(xp, "Risk lot boundary exceeded")` 형태로 간결히 유지되나, 실제 출력되는 파일 로그에는 자동으로 호출된 파일명과 라인, 함수명이 주입되어 **오류 발생 코드를 100% 역추적**할 수 있다.

---

## 4. 로깅 다이어트 상세 설계 매트릭스 (Phase별)

각 Phase별 태스크에서 제거해야 할 로깅 라인과 Backtrace가 적용되어야 할 로그의 구조를 매핑하였다.

```mermaid
graph TD
    %% Define Node Colors
    classDef remove fill:#ffebee,stroke:#c62828,stroke-width:1px;
    classDef keep fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;

    %% Nodes
    N1[Pulse/Polling Loop Logs]:::remove
    N2[Yield/Absence Monitoring Logs]:::remove
    N3[Extreme Trailing Detail Logs]:::remove
    
    K1[Validation / Risk Reject Logs]:::keep
    K2[Order Open/Modify Exec Logs]:::keep
    K3[Sweep / Finalize Completed Logs]:::keep

    %% Grouping
    subgraph REMOVE (Delete & Silence)
        N1
        N2
        N3
    end

    subgraph KEEP (Optimize & Add Backtrace)
        K1
        K2
        K3
    end
```

| Phase | 태스크 / 클래스 | 기존 코드 (Verbose) | 개선 설계 (Minimal with Context) |
| :--- | :--- | :--- | :--- |
| **P1** | `CXStepDiscovery` | `Engine Pulsing: Listening...` (매 주기 출력) | **삭제** |
| **P1** | `CXGuard` / `CXStepValidation` | `XP_LOG_ERROR(xp, "Volume Limit Reject")` | `[CXGuard.mqh:88 in Check] Volume Limit Reject` **(Backtrace 자동 접합)** |
| **P2** | `CXTaskEntry_R_Order` | `Sending Order...` | `[CXTaskEntry_R_Order.mqh:45 in Execute] Sending Order` |
| **P3** | `CXTaskPending_V_Terminal` | `WAIT: Order not visible` (매 주기 출력) | **삭제** |
| **P3** | `CXTaskPending_L_Extreme` | `New Extreme Tracked` (변동 시 대량 출력) | **삭제** (메모리 내부 연산으로 격리) |
| **P3** | `CXTaskPending_R_Apply` | `FAILED: OrderModify failed` | `[CXTaskPending_R_Apply.mqh:94 in Execute] FAILED: OrderModify failed (Code: 10027)` |
| **P4** | `CXTaskActive_TS_TriggerWatch` | `Monitoring State...` | **삭제** |
| **P5** | `CXTaskExit_R_Order` | `Sending Liquidation Order...` | `[CXTaskExit_R_Order.mqh:41 in Execute] Sending Liquidation Order` |

---

## 5. 기존 라이브러리 및 클래스와의 호환성 보장

* **인터페이스 호환성**: `ICXLogger` 및 `CLogify`와 같은 로깅 라이브러리는 내부 함수 시그니처나 포맷을 변경할 필요가 없다. 단지 최상위 매크로(`XP_LOG_*`)의 단순 텍스트 메시지 결합 기능만을 수정하여 주입하므로 기존 코드에 대한 영향도가 0%에 수렴한다.
* **성능 임팩트**: `__FILE__`, `__LINE__`, `__FUNCTION__` 전처리 매크로는 컴파일러가 빌드 타임에 상수로 치환하므로 런타임 성능 저하(오버헤드)가 거의 미미하다.

---
**문서 버전**: v1.0 (PDCA/Design Storage Standard 준수)
**작성 주체**: Antigravity AI Coding System
**승인 상태**: 최초 작성 및 검토 대기
