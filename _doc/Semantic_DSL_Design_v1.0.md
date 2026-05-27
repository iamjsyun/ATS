# Semantic Asset-Centric DSL Design Report (v1.0)

## 1. 개요 (Executive Summary)
본 보고서는 ATSE(Active Trading State Engine)의 차세대 시퀀스 제어 아키텍처인 **'의미 지향 자산 중심 DSL(Semantic Asset-Centric DSL)'**의 설계 명세를 정의한다. 기존의 추상적인 세션(Session) 개념을 탈피하고, MT5의 물리적 자산 속성인 **오더(Order/진트)**와 **포지션(Position/익트)** 도메인으로 이원화하여 직관성과 견고함을 극대화한다.

---

## 2. 도메인 및 상태 정의 (Domain & State Mapping)

| 레이어 | 도메인 | 상태 접두사 | 핵심 책임 |
| :--- | :--- | :---: | :--- |
| **System** | Watcher | `WATCHER_` | DB 신호 감지, 자산 스폰 및 좀비 신호 일괄 정리 (Bulk Sweep) |
| **Order** | Jin-te | `ORD_` | 미체결 오더 자산의 무결성 검증 및 단가 최적화 (Trailing Entry) |
| **Position**| Ik-te | `POS_` | 체결된 포지션의 실시간 감시 및 수익 보존 관리 (Trailing Stop/Alpha) |
| **System** | Infrastructure | `SYS_` | 세션의 최종 종료, 메모리 해제 및 예외 처리 (Cleanup) |

---

## 3. [End-to-End] 시나리오별 DSL 흐름 및 제어 매트릭스

| 레이어 | 시나리오 영역 | 현재 상태 (State) | DSL 정의 (스텝, 태스크 및 제어 흐름) | 비즈니스 로직 및 분기(Branch) |
| :--- | :--- | :--- | :--- | :--- |
| **Watcher** | **신규 진입 감지** | `WATCHER_ENTRY_DISCOVERY` | `> Step_EntryDiscovery ? WATCHER_ENTRY_EXECUTE ! WATCHER_ENTRY_DISCOVERY` | `xa_entry=1` 신규 신호 DB 스캔. |
| (System) | (Discovery) | `WATCHER_ENTRY_EXECUTE` | `> Step_EntryExecute ? WATCHER_ENTRY_DISCOVERY ! WATCHER_ENTRY_DISCOVERY` | 최초 주문 집행 및 **개별 세션(ORD_READY) 스폰**. |
| | **좀비/에러 청산** | `WATCHER_EXIT_DISCOVERY` | `> Step_ExitDiscovery ? WATCHER_EXIT_EXECUTE ! WATCHER_EXIT_DISCOVERY` | `xa_exit=1` 정체된 유령/좀비 신호 스캔. |
| | (Cleanup) | `WATCHER_EXIT_EXECUTE` | `> Step_ExitExecute ? WATCHER_EXIT_DISCOVERY ! WATCHER_EXIT_DISCOVERY` | **[Bulk Sweep]** 세션 없이 남겨진 자산 일괄 강제 처분. |
| **Order** | **진입 준비** | `ORD_READY` | `> Step_OrderValidation : TASK_E_L_VALIDATE, TASK_E_L_RISK ? ORD_EXECUTING ! SYS_ERROR` | 세션 개시. 자본 투입 전 리스크 및 단가 최종 검토. |
| (Asset) | (Jin-te) | `ORD_EXECUTING` | `> Step_OrderPlacement : TASK_E_R_ORDER, TASK_E_V_TICKET ? ORD_PENDING ! SYS_ERROR` | 브로커에 대기/시장가 주문 송신 및 티켓 획득. |
| | **오더 최적화** | `ORD_PENDING` | `> Step_OrderWatch : TASK_A_INTENT_WATCH, TASK_P_V_SYNC ? ORD_TRAILING ! SYS_ERROR * XE_EXECUTED=POS_ACTIVE` | **[분기]** 오더 체결 시 즉시 `POS_ACTIVE`로 점프. |
| | (Trailing Entry) | `ORD_TRAILING` | `> Step_OrderOptimization : TASK_A_INTENT_WATCH, TASK_P_L_EXTREME ? POS_ACTIVE ! SYS_ERROR * XE_EXECUTED=POS_ACTIVE` | 진트(TE). 가격 추적 중 체결 시 포지션 도메인 전이. |
| **Position** | **포지션 감시** | `POS_ACTIVE` | `> Step_PositionWatch : TASK_A_INTENT_WATCH, TASK_A_TS_WATCH ? POS_TRAILING ! SYS_ERROR * XE_CLOSED_SIGNAL=POS_LIQUIDATING` | **[분기]** 내부 익트 조건 또는 DB 청산 신호 시 점프. |
| (Asset) | (Ik-te) | `POS_TRAILING` | `> Step_PositionGovernance : TASK_A_INTENT_WATCH, TASK_A_ALPHA_CALC ? POS_LIQUIDATING ! SYS_ERROR * XE_CLOSED_SIGNAL=POS_LIQUIDATING` | 익트(TS). 알파 로직 기반 수익 추적 및 SL 보정. |
| | **자산 처분** | `POS_LIQUIDATING` | `> Step_PositionLiquidation : TASK_A_INTENT_WATCH, TASK_X_R_ORDER ? SYS_CLOSED ! SYS_ERROR` | 브로커 청산 주문 송신 및 DB 최종 마킹(`xa_exit=2`). |
| **Manual** | **수동 청산** | **모든 자산 상태** | **`TASK_A_INTENT_WATCH` (모든 스텝 최상단 배치)** | 사용자 강제 종료 감지 시 후속 태스크 즉시 중단. |
| (Bypass) | (Fast-Track) | `(Abort & Jump)` | `TASK_A_INTENT_WATCH -> TASK_BREAK -> SYS_CLOSED` | 복잡한 청산 로직을 스킵하고 즉시 `SYS_CLOSED` 직행. |
| **System** | **생애 종료** | `SYS_CLOSED` | `> Step_SystemCleanup : TASK_ACTIVE_CLOSED ? SYS_CLOSED ! SYS_ERROR` | 메모리 해제 및 세션 스레드 종료. |

---

## 4. 핵심 설계 원칙 (Core Principles)

### 4.1. Asset-Logic Cohesion (자산-로직 응집도)
*   **Order Domain (`ORD_`)**: 오더 티켓이 유효한 기간 동안의 모든 로직(진트)을 관장한다.
*   **Position Domain (`POS_`)**: 포지션 티켓이 유효한 기간 동안의 모든 로직(익트)을 관장한다.
*   자산의 전환(Order ➔ Position)은 DSL의 명시적 분기(`* XE_EXECUTED`)를 통해 처리한다.

### 4.2. Intent Watcher Priority (의도 감시 우선순위)
*   모든 `CompositeStep`의 0순위 태스크는 `TASK_A_INTENT_WATCH`로 고정한다.
*   이는 터미널에서의 수동 조작이나 DB의 강제 청산 명령을 시퀀스 엔진보다 먼저 포착하여 불필요한 연산을 차단하고 시스템 안전을 보장하기 위함이다.

### 4.3. Fast-Track Closure (패스트 트랙 종료)
*   자산이 이미 물리적으로 사라진 경우(수동 청산), 청산 명령(`TASK_X_R_ORDER`)을 생략하고 즉시 종료 상태(`SYS_CLOSED`)로 전이하여 리소스를 조기 반환한다.

---
**문서 버전**: v1.0 (PDCA/Design Storage Standard 준수)
**작성 주체**: Antigravity AI Coding System
**작성 일자**: 2026-05-27
