# [Master] ATSE Sequence & Task Architecture (v1.2)

## 1. 개요 (Overview)
본 문서는 **ATSE (Active Trading State Engine)**의 핵심 아키텍처인 **시퀀스(Sequence)**, **스테이지(Stage)**, **원자적 태스크(Task)**의 구조와 매핑을 정의하는 최상위 설계 문서이다.

ATSE는 하드코딩된 논리 결합을 탈피하기 위해 **팩토리 패턴**, **컴포지트 패턴**, **의존성 주입**을 적용했으며, "Step" 용어를 "Stage"로 전면 리팩토링하여 오케스트레이션 계층의 전문성을 강화했다.

---

## 2. 용어 리팩토링 및 상태 진화 (Evolution)

### 2.1 Terminology Alignment
*   **Stage**: 시퀀스의 각 상태(State) 노드를 의미 (기존 'Step' 대체).
*   **Task**: 스테이지 내에서 실행되는 최소 단위의 원자적 논리 블록.
*   **L-P-R-V-P Pipeline**: Logic-Prepare-Request-Verify-Persist로 이어지는 표준 실행 생명주기.

### 2.2 상태 명칭 진화 (Old vs New)
| 기존 명칭 (Old) | 신규 E2E 명칭 (New) | 설명 |
| :--- | :--- | :--- |
| `SESSION_READY` | `ORD_READY` | 주문 전 검증 단계 |
| `SESSION_EXECUTING` | `ORD_EXECUTING` | 브로커 API 주문 송신 |
| `SESSION_PENDING` | `ORD_PENDING` | 터미널 대기 오더 등록 확인 |
| `SESSION_TRAILING_ENTRY`| `ORD_TRAILING` | 트레일링 진입 관리 |
| `SESSION_ACTIVE` | `POS_ACTIVE` | 포지션 체결 및 활성 관리 |
| `SESSION_TRAILING_STOP` | `POS_TRAILING` | 익절 트레일링 스탑 관리 |
| `SESSION_LIQUIDATING` | `POS_LIQUIDATING` | 물리적 청산 이행 |
| `SESSION_CLOSED` | `SYS_CLOSED` | 리소스 해제 및 최종 종료 |

---

## 3. 워처 아키텍처 (Watcher Architecture)
워처는 진입 전담과 청산 전담으로 병렬화되어 독립적으로 구동된다.

| 워처 타입 | 상태 (State) | 스테이지 클래스 | 역할 |
| :--- | :--- | :--- | :--- |
| **Entry Watcher** | `WATCHER_ENTRY_DISCOVERY` | `EntryDiscovery` | 진입 신호(`xa_entry=1`) 검색 |
| | `WATCHER_ENTRY_EXECUTE` | `EntryExecute` | 세션 생성 및 바인딩 |
| **Exit Watcher** | `WATCHER_EXIT_DISCOVERY` | `ExitDiscovery` | 청산 의도(`xa_exit=1`) 검색 |
| | `WATCHER_EXIT_EXECUTE` | `ExitExecute` | 해당 세션 청산 인터럽트 전파 |
| **Zombie Watcher**| `WATCHER_ZOMBIE_DISCOVERY`| `ZombieDiscovery`| DB외 자산 감시 및 역주입 |

---

## 4. 8-Phase 세션 매트릭스 (Session Matrix)

| 상태 (State) | 스테이지 명칭 (DSL) | 주요 태스크 (Tasks) | 성공 (`?`) | 예외 분기 (`*`) |
| :--- | :--- | :--- | :--- | :--- |
| **ORD_READY** | `Stage_OrderValidation` | `L_VALIDATE`, `L_IDENTITY`, `L_RISK`, `P_INTENT` | `ORD_EXECUTING` | - |
| **ORD_EXECUTING** | `Stage_OrderPlacement` | `A_INTENT_WATCH`, `R_ORDER`, `V_TICKET` | `ORD_PENDING` | - |
| **ORD_PENDING** | `Stage_OrderWatch` | `A_INTENT_WATCH`, `V_TERMINAL`, `V_SYNC` | `ORD_TRAILING` | `XE_EXECUTED=POS_ACTIVE` |
| **ORD_TRAILING** | `Stage_OrderOptimization` | `L_REBOUND`, `L_IMPROVE`, `R_APPLY` | `POS_ACTIVE` | `XE_EXECUTED=POS_ACTIVE` |
| **POS_ACTIVE** | `Stage_PositionWatch` | `A_V_TERMINAL`, `A_TS_TRIGGER_WATCH` | `POS_TRAILING` | `XE_CLOSED_SIGNAL=POS_LIQUIDATING` |
| **POS_TRAILING** | `Stage_PositionGovernance` | `A_ALPHA_CALC`, `A_ALPHA_APPLY` | `POS_LIQUIDATING` | `XE_CLOSED_SIGNAL=POS_LIQUIDATING` |
| **POS_LIQUIDATING** | `Stage_PositionLiquidation` | `X_L_PREPARE`, `X_R_ORDER`, `X_V_TERMINAL` | `SYS_CLOSED` | - |
| **SYS_CLOSED** | `Stage_SystemCleanup` | `TASK_ACTIVE_CLOSED` | `SYS_CLOSED` | - |

---

## 5. 태스크 매핑 세부 (Task Details)

### 5.1 Entry Phase (Phase 1)
| 태스크 토큰 | 구체 클래스명 | 역할 |
| :--- | :--- | :--- |
| `TASK_E_L_VALIDATE` | `CXTaskEntry_L_Validate` | 데이터 정합성 확인 |
| `TASK_E_L_RISK` | `CXTaskEntry_L_Risk` | 로트 및 마진 계산 |
| `TASK_E_R_ORDER` | `CXTaskEntry_R_Order` | 브로커 주문 송신 (`OrderOpen`) |

### 5.2 Pending & Trailing Phase (Phase 2)
| 태스크 토큰 | 구체 클래스명 | 역할 |
| :--- | :--- | :--- |
| `TASK_P_L_IMPROVE` | `CXTaskPending_L_Improve` | 더 유리한 가격으로 지정가 갱신 |
| `TASK_P_L_REBOUND` | `CXTaskPending_L_Rebound` | 반등 감시 및 즉시 진입 결정 |

### 5.3 Active & Exit Phase (Phase 3 & 4)
| 태스크 토큰 | 구체 클래스명 | 역할 |
| :--- | :--- | :--- |
| `TASK_A_ALPHA_CALC` | `CXTaskAlphaCalc` | 익절 트레일링 가격(Alpha) 연산 |
| `TASK_X_R_ORDER` | `CXTaskExit_R_Order` | 브로커 시장가 청산 (`PositionClose`) |

---

## 6. 설계상 핵심 안전장치 (Safety Guards)
1.  **Exit-First Priority**: `xa_exit=1` 감지 시 모든 상태를 우회하여 즉시 청산 파이프라인 가동.
2.  **Market-Price Priority**: `price_signal`을 무시하고 실시간 시장가 기준 연산 (`ICXPriceManager`).
3.  **>= Evaluation**: 모든 트레일링 트리거는 `>=` 연산자를 사용하여 신뢰성 확보.
4.  **SSOC (Single Source of Calculation)**: 모든 리스크/가격/심볼 데이터는 전용 Manager 서비스를 통해서만 조회.

---
**Last Updated**: 2026-05-27
