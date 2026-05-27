# [DESIGN] 하이퍼-원자적 스테이지 및 시퀀스 아키텍처 설계 보고서 (v1.0)

본 보고서는 ATSE 엔진의 실행 흐름을 제어하는 **스테이지(Stage)**와 이들의 연결망인 **시퀀스(Sequence)**의 구조를 설계합니다. 특히, 최근 도입된 '자율형 자산 관리'를 수용할 수 있도록 유연하고 견고한 DSL 기반의 상태 전이 체계를 구축합니다.

---

## 1. 아키텍처 계층 구조 (Structural Hierarchy)

ATSE의 실행 단위는 다음과 같은 4단계 계층으로 구성됩니다.

1.  **시그널 (Signal)**: 개별 트레이딩 전략의 최소 단위 (SID 기반).
2.  **시퀀스 (Sequence)**: 시그널의 전체 생애주기(진입~청산)를 정의하는 상태 전이 망.
3.  **스테이지 (Stage)**: 특정 상태에서 수행해야 할 논리적 작업 그룹 (Task들의 집합).
4.  **태스크 (Task)**: 실제 연산을 수행하는 가장 작은 원자적 단위 (Atomic Unit).

---

## 2. 스테이지 설계 (Stage Design)

스테이지는 하나 이상의 원자적 태스크를 순차적으로 실행하며, 결과에 따라 다음 스테이지로의 전이를 결정합니다.

### 2.1 핵심 스테이지 분류
| 스테이지 명칭 | 주요 역할 | 구성 태스크 (예시) |
| :--- | :--- | :--- |
| **Discovery** | 신규 신호 발굴 및 자산 바인딩 | `E_Discovery`, `X_Discovery` |
| **Entry** | 신호 유효성 검증 및 초기 오더 송출 | `E_Risk`, `E_Price`, `R_Order` |
| **Pending** | 대기 오더의 가격 개선 및 진트 수행 | `P_L_Extreme`, `P_L_Improve`, `P_V_Sync` |
| **Active** | 체결된 포지션의 익트 및 리스크 관리 | `A_Alpha_Calc`, `A_Alpha_Apply`, `A_P_Align` |
| **Exit** | 청산 조건 충족 시 주문 삭제 또는 청산 | `X_L_Prepare`, `X_R_Order`, `X_V_Terminal` |
| **Finalize** | DB 업데이트 및 시각화 객체 정리 | `P_Finalize`, `X_P_Finalize` |

---

## 3. 시퀀스 설계 (Sequence Design)

시퀀스는 DSL(Domain Specific Language)을 통해 정의되며, 스테이지 간의 흐름을 통제합니다.

### 3.1 워처 시퀀스 (Watcher Sequence - Global)
시스템 전체의 리소스를 스캔하고 새로운 작업을 할당하는 전역 루프입니다.
*   **Flow**: `Bootstrap -> Discovery -> Execute -> Discovery (Loop)`

### 3.2 세션 시퀀스 (Session Sequence - Local)
개별 SID(자산) 단위로 동작하는 독립적 트레일링 루프입니다.
*   **Pending Sequence (진트)**: 오더 체결 전까지 `ORD_TRACKING` 스테이지를 반복 순회.
*   **Active Sequence (익트)**: 포지션 종료 전까지 `POS_MONITORING` 스테이지를 반복 순회.

---

## 4. DSL 기반 상태 전이 매트릭스 (Transition Matrix)

ATSE는 다음과 같은 DSL 형식을 사용하여 시퀀스를 정의합니다.
`[현재 스테이지] > [실행 스테이지/태스크] ? [성공 시 전이] ! [실패 시 전이] @ [타임아웃]`

### 4.1 진입 및 대기 시퀀스 예시
```dsl
// 오더 트레킹 (진트)
ORD_TRACKING > Stage_OrderOptimization 
    ? ORD_TRACKING // 성공 시 자기 반복 (트레일링 지속)
    ! SYS_ERROR    // 실패 시 에러 처리
    * 10=POS_MONITORING // 체결 이벤트(10) 발생 시 포지션 모니터링으로 강제 전이
```

### 4.2 포지션 및 청산 시퀀스 예시
```dsl
// 포지션 모니터링 (익트)
POS_MONITORING > Stage_PositionGovernance
    ? POS_MONITORING
    ! SYS_ERROR
    * 20=SESSION_LIQUIDATING // 청산 신호(20) 발생 시 청산 스테이지로 전이
```

---

## 5. 설계의 핵심 특징

### 5.1 하이퍼-원자성 (Hyper-Atomicity)
*   각 태스크는 서로의 내부 상태를 알 필요가 없습니다. 오직 `ICXParam`과 `ICXContext`를 통해서만 소통합니다.
*   스테이지는 태스크들의 조합(Composition)일 뿐이며, 언제든 새로운 태스크를 끼워 넣거나 뺄 수 있습니다.

### 5.2 자율형 자산 관리와의 통합
*   `OrderManager`와 `PositionManager`는 이 시퀀스 엔진 위에서 동작하는 '실행 엔진' 역할을 합니다.
*   이벤트 발생 시 관리자가 `Signal`의 상태 값을 변경하면, 시퀀스 엔진이 이를 감지하여 즉시 다음 스테이지로 전이시킵니다.

### 5.3 장애 복구성 (Fault Tolerance)
*   어떤 스테이지에서 중단되더라도, 자산 관리자가 터미널 자산을 다시 스캔하면 SID를 기반으로 중단되었던 스테이지부터 즉시 재개할 수 있습니다.

---

## 6. 결론
본 스테이지 및 시퀀스 설계는 ATSE의 복잡한 트레이딩 로직을 명확한 상태 기계(State Machine)로 정형화합니다. 이를 통해 개발자는 복잡한 흐름 제어 코드 대신, 원자적 태스크 로직 개발에만 집중할 수 있으며, 시스템은 어떠한 예외 상황에서도 SID 기반의 일관된 실행 흐름을 유지하게 됩니다.
