### **[ UAF v14.4 Standardized Nomenclature with Ticket & Magic ]**
> `[FUNC:Name] [SID] [TK:Value, M:Magic] [Sym, Lot, Dir, Status] [ESTART:d, ESTEP:d, ELIMIT:d, ESTART_PRICE:f, ELIMIT_PRICE:f SSTART:d, SSTEP:d SL:d TP:d] [P:f, SL:f, TP:f, Mkt:f] {SPEC:Extra}`

---

**Version**: v11.16 (UAF Nomenclature Sync & Exit-First Priority)
**Date**: 2026-05-27

---

## 1. Core Principles
- **Intelligent Trailing Entry (Mandatory Case Scenario)**: 진입 파이프라인은 다음 3단계의 정밀 시퀀스를 준수해야 한다.
    1. **Initial Placement**: 신규 신호 바인딩 시, 시장가로부터 **`ELIMIT`** 거리만큼 떨어진 지점에 최초 대기 오더를 접수한다.
    2. **Trailing Activation**: 시장가가 최초 진입 시점 대비 **`ESTART`** 포인트 이상 하락(Buy 기준)할 때 비로소 추격(Trailing)을 시작한다.
    3. **Rebound Execution**: 시장이 바닥을 찍고 **`ESTEP`** 포인트 이상 반등하는 순간, 대기 오더를 즉시 취소하고 **시장가(Market)**로 진입한다.
- **Exit-First Priority Mandate (Critical)**: 청산 의도(`xa_exit=1`)가 감지되면 시스템은 현재의 에러 상태(`xe_status=99`)나 진행 중인 진입 시퀀스를 즉시 우회하여 청산 파이프라인을 최우선으로 가동해야 한다. Watcher는 이를 위해 `xa_exit=1` 신호를 최상단으로 정렬하여 로드한다.
- **>= Evaluation Mandate (Critical)**: 모든 트레일링 파라미터(ESTART, ESTEP, ELIMIT, SSTART, SSTEP)는 대입 시에는 `=`를 사용하되, 코드 내의 조건문에서 평가될 때는 반드시 **`>=` (크거나 같다)** 연산자를 사용해야 한다.
- **Mandatory Pre-Call Audit (Critical)**: 브로커 통신 함수 호출 **직전**에, 해당 함수에 전달되는 모든 로우(Raw) 파라미터를 포함한 감사 로그를 반드시 기록해야 한다. 
- **Mandatory Ticket Guard (Liquidation)**: 청산 프로세스(Stage_PositionLiquidation)는 반드시 유효한 물리적 티켓(`Ticket > 0`)이 존재하는 경우에만 트리거될 수 있다.

- **Responsibility Segregation**: Operations are strictly separated by domain: `OrderManager` for orders, `PositionManager` for active positions.
- **Interface-First Mandate**: 모든 도메인 로직은 인터페이스에 의존해야 한다. 시스템은 **전역 관리 서비스(ICX...)**와 **트레이딩 실행 매니저(IX...)**로 이원화되어 운영된다.
- **MQL5 Memory Governance (Mandatory)**: 모든 인터페이스 및 클래스는 반드시 `CObject`를 상속받아야 한다. 이는 `CArrayObj` 등 표준 컬렉션과의 호환성 및 안전한 메모리 해제(SAFE_DELETE)를 보장하기 위함이다.
- **DataManager State Governance (v9.8.11)**: 관리 UI는 권위 있는 상태 전이 매트릭스를 통해 신호의 생명주기를 통제한다.

---

## 2. System Architecture

### 2.1. 데이터 스키마 (signals 테이블 / 41개 필드)
시스템의 모든 영속 데이터는 SQLite의 `signals` 테이블을 기준으로 관리된다.

| 분류 | 필드명 | 타입 | 상세 설명 |
| :--- | :--- | :---: | :--- |
| **식별자** | `id`, `sid`, `gid` | PK, string | 레코드 ID, 신호 식별자, 그룹 식별자 |
| | `cno`, `sno` | int | 채널 번호, 세션 번호 |
| | `msg_id`, `raw_id` | int | 텔레그램 메시지 ID, 원본 데이터 ID |
| **의도 및 상태** | `xa_entry`, `xa_exit` | int | 진입 의도(1=ACTIVE), 청산 의도(1=ACTIVE, 2=COMP, 3=ARCH) |
| | `xe_status`, `xe_status_msg` | int, text | 상세 실행 상태 코드 및 결과 메시지 |
| **시장 정보** | `time`, `symbol`, `dir`, `type` | string, int | 신호 발생 시간, 심볼, 방향(1=Buy, 2=Sell), 타입(1=Trl, 2=Lim, 3=Stop, 9=Mkt) |
| | `price_signal`, `lot` | double | 신호 발생 당시 가격, 주문 로트 수량 |
| **트레일링(TE/TS)** | `te_start`, `te_step`, `te_limit` | double | 트레일링 진입 시작점, 간격, 한계점 |
| | `te_interval`, `ikte_start`, `ikte_step` | int, double | 트레일링 체크 간격, 익절 트레일링 시작/간격 |
| **리스크 및 목표** | `tp`, `sl` | double | 목표가(TP), 손절가(SL) |
| | `ts_start`, `ts_step`, `close_type` | int | 트레일링 스탑 시작/간격, 종료 타입 |
| **물리 실행 정보** | `trail_price`, `price_limit`, `price` | double | 현재 추적 가격, 진입 한계가, 최종 실행가 |
| | `price_open`, `price_close` | double | 실물 오픈 가격, 실물 청산 가격 |
| | `price_tp`, `price_sl` | double | 실물 적용 TP/SL 가격 |
| | `ticket`, `magic` | numeric | 브로커 티켓 번호, 엑스퍼트 매직 넘버 |
| **메타데이터** | `comment`, `tag` | string | 주문 코멘트, 태그 |
| | `created`, `updated` | datetime | 생성일시, 수정일시 |

### 2.2 Framework Fundamentals (MQL5 Implementation)
- **Dependency Injection (CXContext)**: Service Locator & DI Container.
- **Message Passing (CXParam)**: Transient Event DTO.
- **Surgical Resolve (CX_GET_OBJ)**: Type-safe service resolution.

### 2.3 ID Design Rules (v8.2)
- **SID (Signal ID)**: `CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1)` (총 23자)
- **GID (Group ID)**: `CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)` (총 19자)

### 2.4 AppOrchestrator Sequence-Class Mapping (v18.8)
하이퍼-원자적 8-Phase 시퀀스의 각 단계별 DSL 명칭과 실제 실행되는 MQL5 구체 클래스의 전체 매칭 정보이다.

| 시퀀스 상태 (State) | DSL 스테이지 명칭 | 실행 태스크 (DSL Task Name) | 구체 클래스 (MQL5 Class) |
| :--- | :--- | :--- | :--- |
| **ORD_READY** | `Stage_OrderValidation` | **TASK_E_L_VALIDATE** | `CXTaskEntry_L_Validate` |
| | | `TASK_E_L_IDENTITY` | `CXTaskEntry_L_Identity` |
| | | `TASK_E_L_RISK` | `CXTaskEntry_L_Risk` |
| | | `TASK_E_L_PRICE` | `CXTaskEntry_L_Price` |
| | | `TASK_E_G_SPREAD` | `CXTaskGuard_V_Spread` |
| | | `TASK_E_P_INTENT` | `CXTaskEntry_P_Intent` |
| **ORD_EXECUTING** | `Stage_OrderPlacement` | `TASK_E_R_ORDER` | `CXTaskEntry_R_Order` |
| | | `TASK_E_V_ERROR` | `CXTaskEntry_V_Error` |
| | | `TASK_E_V_TICKET` | `CXTaskEntry_V_Ticket` |
| **ORD_PENDING** | `Stage_OrderWatch` | `TASK_A_INTENT_WATCH` | `CXTaskIntentWatch` |
| | | `TASK_P_V_TERMINAL` | `CXTaskPending_V_Terminal` |
| | | `TASK_P_V_SYNC` | `CXTaskPending_V_Sync` |
| **ORD_TRAILING** | `Stage_OrderOptimization` | `TASK_A_INTENT_WATCH` | `CXTaskIntentWatch` |
| | | `TASK_P_L_EXTREME` | `CXTaskPending_L_Extreme` |
| | | `TASK_P_L_REBOUND` | `CXTaskPending_L_Rebound` |
| | | `TASK_P_L_IMPROVE` | `CXTaskPending_L_Improve` |
| | | `TASK_P_R_APPLY` | `CXTaskPending_R_Apply` |
| | | `TASK_P_V_SYNC` | `CXTaskPending_V_Sync` |
| **POS_ACTIVE** | `Stage_PositionWatch` | `TASK_A_INTENT_WATCH` | `CXTaskIntentWatch` |
| | | `TASK_A_V_TERMINAL` | `CXTaskActive_V_Terminal` |
| | | `TASK_A_TS_TRIGGER_WATCH`| `CXTaskActive_TS_TriggerWatch` |
| **POS_TRAILING** | `Stage_PositionGovernance` | `TASK_A_INTENT_WATCH` | `CXTaskIntentWatch` |
| | | `TASK_A_ALPHA_CALC` | `CXTaskAlphaCalc` |
| | | `TASK_A_ALPHA_APPLY` | `CXTaskAlphaApply` |
| | | `TASK_A_V_TERMINAL` | `CXTaskActive_V_Terminal` |
| **POS_LIQUIDATING** | `Stage_PositionLiquidation` | `TASK_A_INTENT_WATCH` | `CXTaskIntentWatch` |
| | | `TASK_X_L_PREPARE` | `CXTaskExit_L_Prepare` |
| | | `TASK_X_P_LOCK` | `CXTaskExit_P_Lock` |
| | | `TASK_X_R_ORDER` | `CXTaskExit_R_Order` |
| | | `TASK_X_V_ERROR` | `CXTaskExit_V_Error` |
| | | `TASK_X_V_TERMINAL` | `CXTaskExit_V_Terminal` |
| | | `TASK_X_P_FINALIZE` | `CXTaskExit_P_Finalize` |
| **SYS_CLOSED** | `Stage_SystemCleanup` | `TASK_ACTIVE_CLOSED` | `CXTaskActive_Closed` |

### 2.5 DataManager State Transition Matrix (v9.8.11)

#### 2.3.1 Logical Intent Matrix (Governance)
| 작업 명칭 | xa_entry | xa_exit | xe_status | 상세 설명 |
| :--- | :---: | :---: | :---: | :--- |
| **신규 주입 (Save)** | **1** | **0** | **0 (READY)** | 신규 신호 READY 상태 |
| **청산 요청 (Exit)** | 유지 | **1 (ACTIVE)** | 유지 | 청산 명령 ACTIVE 상태 |
| **청산 완료 (Comp)** | 유지 | **2 (COMP)\*** | **20 (CLOSED)** | 실행 계층 강제 종료 마킹 (\*Manual Only) |
| **이관 대기 (Arch)** | 유지 | **3 (ARCH)\*\*** | 유지 | 아카이브 대기 상태 (\*\*ATSA 소관) |

> **\*의도 필드(xa_*) 직접 수정 예외**: 의도는 원칙적으로 App(ATSA)의 소관이나, 다음의 경우 ATSE가 직접 수정할 수 있다.
> 1. **Handshake Acceleration**: 수동 종료(`xe_status=24`) 감지 시 `xa_exit=2`를 직접 마킹하여 빠른 종료 유도.
> 2. **Zombie Recovery**: 터미널 실물 역주입 시 `xa_entry=1`을 직접 마킹하여 세션 관리 대상으로 편입.

#### 2.3.2 Physical Execution States (xe_status Details)
실행 계층(ATSE)은 다음의 상세 상태 코드를 사용하여 생명주기를 관리한다.
1. **READY (0)**: 신호 최초 주입 및 대기.
2. **PENDING_REQ (1)**: 브로커로 대기 주문(Limit/Stop) 송신 중.
3. **IN_TRANSIT (2)**: 시장가(Market) 주문 송신 및 체결 대기 중.
4. **PENDING_PLACED (5)**: 대기 주문이 브로커 터미널에 정상 등록됨.
5. **EXECUTED (10)**: 실제 포지션 오픈 완료 (Active Trading).
6. **QUARANTINED (15)**: 좀비 자산(Orphan Asset) 격리 상태. 실물은 존재하나 사용자의 승인 전까지 자동 트레일링 및 청산 로직이 중단된 Hold 상태.
7. **CLOSED_SIGNAL (20)**: 사용자/시스템 신호에 의한 청산 완료.
8. **CLOSED_SL (21)**: Stop Loss에 의한 강제 청산 완료.
9. **CLOSED_TP (22)**: Take Profit에 의한 청산 완료.
10. **CLOSED_MANUAL (24)**: 사용자의 터미널 직접 조작에 의한 수동 청산 완료.
11. **VERIFY_ABS / Finalize (25)**: 자산 부재 및 히스토리 최종 검증 상태. (코드상의 23단계와 연계되어 최종 세션 해제 수행)
12. **ERROR (99)**: 치명적 에러 발생 및 시스템 강제 종료.

---

## 3. Engineering Protocols

### 3.1 Post-Action Verification (Mandatory)
Every trading action must verify physical state in MT5 immediately after the request.

### 3.2 Memory Safety & Inheritance
- **Base Class Mandate**: 모든 커스텀 객체(인터페이스, 모델 등)는 `CObject`를 상속하여 포인터 관리의 일관성을 유지한다.
- **Null Guard**: `SAFE_DELETE`와 `IS_VALID` / `IS_INVALID` 매크로를 사용하여 댕글링 포인터를 방지한다.

### 3.3 Sequence Design & Task Atomization (v9.7)
모든 비즈니스 로직 시퀀스는 원자적 태스크 단위로 분해되어야 하며, **1 Task = 1 Responsibility (SRP 준수)** 원칙을 강제한다.

### 3.4 Trading Process Standard (v11.3 - Mandatory)

시스템은 서비스의 성격에 따라 두 종류의 인터페이스 접두사를 사용한다.
- **ICX (Core Services)**: 시스템 전반의 정책 및 데이터를 관리하는 전역 서비스 (Price, Risk, Symbol, Inventory 등).
- **IX (Execution Managers)**: 실제 트레이딩 액션을 수행하는 실행 계층 매니저 (Order, Position, Entry, Exit 등).

#### 3.4.1 Price Management Mandate (SSOC)
- **Single Source of Calculation**: 모든 가격 계산(시장가, 오더가, SL/TP)은 반드시 `ICXPriceManager` 서비스를 통해서만 수행한다.
- **무결성 가드**: 매수/매도 지정가가 시장가를 역전할 경우 자동으로 시장가 보정하여 `10015` 에러 차단.

#### 3.4.2 Risk Management Mandate (SSOC)
- **Single Source of Validation**: 로트(Volume) 및 마진(Margin) 관련 검증은 반드시 `ICXRiskManager` 서비스를 통해서만 수행한다.
- **마진 선제 검증**: 주문 송신 전 가용 증거금을 체크하여 `134 (Not enough money)` 에러 사전 차단.

#### 3.4.3 Symbol Management Mandate (SSOC)
- **Single Source of Specification**: 모든 심볼 속성 조회(`Point`, `Digits`, `StopsLevel` 등)는 반드시 `ICXSymbolManager` 서비스를 통해서만 수행한다.
- **성능 최적화 (Caching)**: 한 틱 내에서 발생하는 중복 API 호출 방지를 위해 속성 캐싱을 강제한다.

#### 3.4.4 Inventory Management Mandate (SSOC)
- **Single Source of Inventory**: 터미널 실물 자산(Position/Order)의 존재 여부 및 속성 조회는 반드시 `ICXInventoryManager` 서비스를 통해서만 수행한다.
- **State Shadowing**: 실물 확인 성공 시, 터미널의 최신 데이터(Volume, PriceOpen, SL, TP)를 즉시 메모리 내 `ICXSignal` 모델로 동기화하여 데이터 정합성을 유지한다.

#### 3.4.5 Trading Logging Standard v11.1 (Extended)
- **실패 로그 강화**: 에러 발생 시 `CTrade::OrderSend`에 전달된 모든 로우(Raw) 파라미터를 로그에 강제 포함한다.

#### 3.4.6 Execution Management (IX)
- **Atomic Operations**: `IXOrderManager` 및 `IXPositionManager`는 브로커와의 통신 및 실물 자산 수정을 담당하며, 모든 호출은 원자적으로 처리되어야 한다.

#### 3.4.7 로깅 및 사후 검증 규칙 (Execution & Verify)
1.  **전역 파라미터 로깅**: 모든 트레이딩 함수 호출 시 인자 전체와 주요 트레일링 파라미터를 상세 로그에 기록한다.
2.  **결과 로깅**: 브로커 리턴 코드와 응답 메시지를 반드시 기록한다.
3.  **물리적 자산 재검색**: 함수 호출 직후 터미널의 실물 자산 존재 여부를 재확인한다.

### 3.5 High-Priority Exit & Interrupt Protocol (v11.5)
자산 보호와 시퀀스 무결성을 위해 청산(Exit) 의도는 모든 파이프라인에서 최우선 순위로 처리된다.

#### 3.5.1 Priority Intent Discovery
- **Watcher Mandate**: 신호 감지 단계(`Discovery`)에서 `xa_exit=1`인 신호를 최상단으로 정렬하여 로드하며, 활성 세션 풀에 즉시 인터럽트 신호를 전파한다.

#### 3.5.2 Session Force-Transition (Interrupt)
- **Immediate Jump**: 진입(Entry) 또는 활성(Active) 상태와 무관하게 청산 의도가 감지되면 즉시 `State 20 (Liquidation Pipeline)`으로 강제 전이한다.
- **Idempotency Guard**: 인터럽트로 인한 중복 진입 시에도 실제 브로커 명령 송신 여부를 체크하여 중복 요청(`10027`)을 방지한다.

#### 3.5.3 Manual-Close Fast-Path (Zombie Protection)
- **L3 Detection**: 모든 상태의 인덱스 0번 태스크(`TASK_A_INTENT_WATCH`)는 매 틱마다 터미널 실물 티켓 소멸 여부를 감시한다.
- **Direct Jump**: 사용자의 수동 청산 등으로 티켓이 소멸된 것이 확인되면, 청산 명령 단계를 건너뛰고 즉시 **State 23 (Finalize / EXIT_VERIFY)**으로 도약하여 세션을 즉시 해제한다.
- **Handshake Acceleration (Exception)**: 수동 청산 감지(`xe_status=24`) 시, EA는 예외적으로 `xa_exit=2 (COMP)`를 직접 마킹할 수 있다.
- **Reverse Injection (Exception)**: 터미널 스캔 중 DB에 없는 매직넘버 일치 자산 발견 시, EA는 예외적으로 `xa_entry=1`을 직접 마킹하여 좀비 자산을 복구한다.

---
**Last Updated**: 2026-05-27
