# ATS Master Design Specification (SSOT)
**Version**: v11.5 (High-Priority Exit Standard)
**Date**: 2026-05-19
**Governance**: This document is the **Single Source of Truth (SSOT)** for the ATS/XTA system. All implementations must adhere to these specifications.

---

## 1. Overview & Philosophy
The ATS system is a modern, object-oriented trading engine designed to replace complex procedural logic with **Declarative Orchestration** and **Reactive State Management**.

### 1.1 Core Principles
- **Intent-Execution Separation**: Decouple "What to do" (App Intent) from "How it's running" (EA Execution).
- **Post-Action Verification Protocol**: All trading actions (Entry, Modification, Closure) MUST be followed by a terminal re-check (via `OrderSelect` or `PositionSelect`) to ensure logical success matches physical state.
- **Responsibility Segregation**: Operations are strictly separated by domain: `OrderManager` for orders, `PositionManager` for active positions.
- **Interface-First Mandate**: All domain logic must depend on IX* interfaces.
- **DataManager State Governance (v9.8.11)**: The management UI governs the signal lifecycle through an authoritative state transition matrix.

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

### 2.4 DataManager State Transition Matrix (v9.8.11)

#### 2.3.1 Logical Intent Matrix (Governance)
| 작업 명칭 | xa_entry | xa_exit | xe_status | 상세 설명 |
| :--- | :---: | :---: | :---: | :--- |
| **신규 주입 (Save)** | **1** | **0** | **0 (READY)** | 신규 신호 READY 상태 |
| **청산 요청 (Exit)** | 유지 | **1 (ACTIVE)** | 유지 | 청산 명령 ACTIVE 상태 |
| **청산 완료 (Comp)** | 유지 | **2 (COMP)** | **20 (CLOSED)** | 실행 계층 강제 종료 마킹 |
| **이관 대기 (Arch)** | 유지 | **3 (ARCH)** | 유지 | 아카이브 대기 상태 |

#### 2.3.2 Physical Execution States (xe_status Details)
실행 계층(ATSE)은 다음의 상세 상태 코드를 사용하여 생명주기를 관리한다.
1. **READY (0)**: 신호 최초 주입 및 대기.
2. **PENDING_REQ (1)**: 브로커로 대기 주문(Limit/Stop) 송신 중.
3. **IN_TRANSIT (2)**: 시장가(Market) 주문 송신 및 체결 대기 중.
4. **PENDING_PLACED (5)**: 대기 주문이 브로커 터미널에 정상 등록됨.
5. **EXECUTED (10)**: 실제 포지션 오픈 완료 (Active Trading).
6. **CLOSED_SIGNAL (20)**: 사용자/시스템 신호에 의한 청산 완료.
7. **CLOSED_SL (21)**: Stop Loss에 의한 강제 청산 완료.
8. **CLOSED_TP (22)**: Take Profit에 의한 청산 완료.
9. **ERROR (99)**: 치명적 에러 발생 및 시스템 강제 종료.

---

## 3. Engineering Protocols

### 3.1 Post-Action Verification (Mandatory)
Every trading action must verify physical state in MT5 immediately after the request.

### 3.2 Memory Safety
- Use `SAFE_DELETE` and `IS_VALID` / `IS_INVALID`.

### 3.3 Sequence Design & Task Atomization (v9.7)
모든 비즈니스 로직 시퀀스는 원자적 태스크 단위로 분해되어야 하며, **1 Task = 1 Responsibility (SRP 준수)** 원칙을 강제한다.

### 3.4 Trading Process Standard (v11.3 - Mandatory)

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
...
- **실패 로그 강화**: 에러 발생 시 `CTrade::OrderSend`에 전달된 모든 로우(Raw) 파라미터를 로그에 강제 포함한다.

#### 3.4.5 로깅 및 사후 검증 규칙 (Execution & Verify)
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
- **Direct Jump**: 사용자의 수동 청산 등으로 티켓이 소멸된 것이 확인되면, 청산 명령 단계를 건너뛰고 즉시 `State 23 (Finalize)`으로 도약하여 세션을 즉시 해제한다.
- **Handshake Acceleration (Exception)**: 수동 청산 감지(`xe_status=24`) 시, EA는 예외적으로 `xa_exit=2 (COMP)`를 직접 마킹할 수 있다. 이는 App(ATSA)의 동기화 지연을 우회하여 즉시 '이관 대기(3)'로 전이하기 위한 최적화 경로이다.

---
**Last Updated**: 2026-05-23
