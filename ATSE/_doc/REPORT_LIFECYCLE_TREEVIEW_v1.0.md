# [Report] ATSE Signal Lifecycle Tree-View Analysis (v1.1)

## 1. 개요 (Overview)
본 보고서는 ATSE 프레임워크 내에서 트레이딩 신호가 감지되는 순간부터 최종 청산되어 세션이 반환되기까지의 전체 프로세스를 계층형 트리뷰(Tree-View) 형식으로 기술한다. 특히 핵심 매매 기법인 **진입 트레일링(진트)**, **익절 트레일링(익트)**, **청산** 프로세스에 대한 정밀 분석을 포함한다.

---

## 2. 프로세스 트리뷰 (Process Tree-View)

### Phase 1: 신호 감지 및 바인딩 (Watcher Lifecycle)
*   **[Context: Global/Watcher]**
    *   `ST_W_DISCOVERY` (신호 발견)
        *   `STEP_W_DISCOVERY`: SQLite `signals` 테이블 상시 감시 (`xa_entry=1`)
    *   `ST_W_VALIDATION` (유효성 검증)
        *   `STEP_W_VALIDATION`: `CXGuard` 기반 필드 무결성 및 시장 환경 체크
    *   `ST_W_BINDING` (세션 할당)
        *   `STEP_W_BINDING`: `SessionPool` 유휴 세션 확보 및 신호 주입(Inject)

### Phase 2: 진입 파이프라인 (Entry Execution)
*   **[Context: Global/[SID]]**
    *   `ST_S_READY` (진입 로직 및 송신)
        *   `TASK_E_L_VALIDATE`: 최종 비즈니스 규칙 재검증
        *   `TASK_E_G_SPREAD / VOLATILITY`: 실시간 스프레드 및 변동성 가드
        *   `TASK_E_P_LOCK`: DB 상태 `XE_PENDING_REQ` 잠금
        *   `TASK_E_R_ORDER`: 브로커 주문 송신 (`m_trade.OrderOpen`)
    *   `ST_S_ENTRY_TRANSIT` (송신 결과 확인)
        *   `TASK_E_V_ERROR`: 서버 응답 코드 분석 및 로깅
        *   `TASK_E_V_TICKET`: 생성된 오더/포지션 티켓 인식
        *   `TASK_E_V_REAL`: 터미널 실물 자산 존재 여부 교차 검증
    *   `ST_S_ENTRY_VERIFY` (최종 확정)
        *   `TASK_E_V_DOUBLECHECK`: SID 정합성 및 체결 가격 최종 확인
        *   `TASK_E_P_FINALIZE`: DB 상태 `XE_EXECUTED` 업데이트 (대기 주문일 경우 `ST_S_ENTRY_TRAILING`으로 전이)

### Phase 2.5: 대기 주문 및 진입 트레일링 (Pending & Trailing Entry - 진트)
*   **[Context: Global/[SID]]**
    *   `ST_S_ENTRY_TRAILING` (지정가 대기 및 가격 추적)
        *   `TASK_P_V_SYNC`: 터미널의 대기 주문(Pending Order) 상태 동기화
        *   `TASK_P_L_REBOUND`: 가격 반등 조건(TeLimit) 충족 여부 검사
        *   `TASK_P_L_IMPROVE`: 더 유리한 가격(TeStep)으로의 추적 계산
        *   `TASK_P_R_APPLY`: 브로커 주문 가격 수정 (`OrderModify`)

### Phase 3: 활성 관리 및 익절 트레일링 (Active & Trailing Profit - 익트)
*   **[Context: Global/[SID]]**
    *   `ST_S_ACTIVE` (상태 감시 및 트레일링)
        *   `TASK_A_INTENT_WATCH`: UI 청산 명령(`xa_exit=1`) 실시간 감시
        *   `TASK_A_V_STATUS`: 터미널 포지션 강제 종료(SL/TP) 감지
        *   `TASK_A_V_TERMINAL`: 고아 포지션 및 좀비 상태 방지
        *   `TASK_A_P_ALIGN`: P-L(실물-논리) 불일치 시 자가 치유
        *   `TASK_A_ALPHA_CALC`: 현재가 기준 트레일링(IkTe/TS) 가격 산출
        *   `TASK_A_ALPHA_APPLY`: 브로커 수정 요청(`m_trade.PositionModify`)

### Phase 4: 청산 파이프라인 (Liquidation)
*   **[Context: Global/[SID]]**
    *   `ST_S_LIQUIDATING` (청산 준비 및 실행)
        *   `TASK_X_L_PREPARE`: 청산 물량 및 타겟 가격 계산
        *   `TASK_X_P_LOCK`: DB 상태 `XE_IN_TRANSIT` 잠금
        *   `TASK_X_R_ORDER`: 브로커 청산 요청 (`m_trade.PositionClose`)
    *   `ST_S_LIQUIDATING_TRANSIT` (청산 결과 확인)
        *   `TASK_X_V_ERROR`: 청산 성공 코드 분석
        *   `TASK_X_V_TERMINAL`: 포지션 소멸 여부 실물 확인
    *   `ST_S_EXIT_VERIFY` (최종 종료 및 반환)
        *   `TASK_X_P_FINALIZE`: DB 상태 `XE_CLOSED` 업데이트
        *   `Reset()`: 세션 컨텍스트 트리 해제 및 `SessionPool` 반환

---

## 3. 핵심 알고리즘 정밀 분석 (Deep Dive)

### 3.1 진입 트레일링 (진트, Trailing Entry)
진입 트레일링은 즉시 시장가로 진입하지 않고, 가격이 유리해지는 방향으로 대기 주문(Pending Order)을 끌고 내려가다가(추적), 반등할 때 체결시키는 고급 진입 기법입니다.

*   **동작 조건**: 신호의 `te_start`(활성화 거리), `te_step`(추적 간격), `te_limit`(반등폭) 필드가 활성화되었을 때 `ST_S_ENTRY_TRAILING` 상태에서 구동됩니다.
*   **원자적 처리 로직 (Atomicity)**:
    1.  **동기화 (`TASK_P_V_SYNC`)**: 현재 터미널에 등록된 지정가 주문(Limit/Stop)의 실제 가격을 읽어옵니다.
    2.  **개선 추적 (`TASK_P_L_IMPROVE`)**: 현재 시장가(Ask/Bid)가 대기 주문 가격보다 `te_step` 이상 유리해지면, 새로운 진입 타겟 가격을 계산합니다.
    3.  **반등 감지 (`TASK_P_L_REBOUND`)**: 가격이 계속 유리해지다가 갑자기 `te_limit` 만큼 반대 방향으로 튀어오르면(반등), 추적을 멈추고 즉시 시장가 진입(또는 대기 주문을 현재가 턱밑으로 바짝 올림)을 결정합니다.
    4.  **반영 (`TASK_P_R_APPLY`)**: 계산된 새로운 가격으로 브로커에게 `OrderModify`를 전송합니다.
*   **안전장치**: 터미널의 가격이 이미 체결되어 포지션으로 전환된 경우, `TASK_P_V_SYNC`가 이를 감지하고 즉시 시퀀스를 `ST_S_ACTIVE`로 건너뛰게(Jump) 하여 논리적 꼬임을 방지합니다.

### 3.2 익절 트레일링 (익트, Trailing Profit / IkTe)
포지션이 수익권에 접어들었을 때, 수익을 확보한 채로 이익 실현선(TP) 또는 손절선(SL)을 가격을 따라 이동시키는 기법입니다. ATSE는 전통적인 TS(Trailing Stop)와 자체적인 IkTe(익절 트레일링)를 모두 지원합니다.

*   **동작 조건**: 체결된 포지션이 존재하고 상태가 `ST_S_ACTIVE`일 때, 지속적으로 실행됩니다.
*   **원자적 처리 로직 (Atomicity)**:
    1.  **알파 계산 (`TASK_A_ALPHA_CALC`)**: 
        *   현재 실시간 시장가를 가져옵니다 (Mandate v10.23 준수: 신호 주입 가격 무시, 절대 시장가 기준).
        *   수익이 `ikte_start`(또는 `ts_start`) 포인트를 돌파했는지 확인합니다.
        *   돌파했다면, 고점(최대 수익점)을 기록하고 이로부터 `ikte_step`만큼 뒤처진 가격을 새로운 안전선(SL)으로 계산합니다.
    2.  **알파 적용 (`TASK_A_ALPHA_APPLY`)**:
        *   기존 SL 가격과 새로 계산된 SL 가격을 비교합니다. 
        *   유의미한 차이(Broker Stop Level 및 Slippage 초과)가 있을 경우에만 브로커에게 `PositionModify` 요청을 보냅니다. (불필요한 서버 스팸 공격 차단).
*   **안전장치**: 계산 도중 포지션이 수동 청산되거나 SL/TP에 닿아 소멸한 경우, 선행 태스크인 `TASK_A_V_TERMINAL`이 이를 먼저 감지하여 계산을 중단시키고 `ST_S_LIQUIDATING` 프로세스로 강제 유도합니다.

### 3.3 청산 파이프라인 (Liquidation)
단순한 1회성 종료가 아닌, DB 상태 잠금(Lock)부터 브로커 확인, 터미널 소멸 검증까지 이어지는 **"3단계 하이퍼-원자성 방어선"**입니다.

*   **동작 조건**: UI에서 `xa_exit=1` 명령이 떨어지거나, 익트/손절에 의해 포지션이 닫힌 것으로 판단될 때 `ST_S_LIQUIDATING`으로 진입합니다.
*   **원자적 처리 로직 (Atomicity)**:
    1.  **잠금 및 1차 송신 (`Exit Logic`)**: DB의 신호 상태를 `XE_IN_TRANSIT`으로 변경하여, 외부 프로세스나 다른 워처가 이 신호를 건드리지 못하게 Lock을 겁니다. 이후 터미널에 `PositionClose` 명령을 전송합니다.
    2.  **물리적 소멸 확인 (`Exit Transit`)**: 브로커의 Return Code를 파싱하여 성공(Deal 생성)을 확인한 뒤, **반드시 MT5 터미널의 활성 포지션 리스트를 재검색**(`TASK_X_V_TERMINAL`)하여 실물이 완전히 사라졌음을 눈으로 확인합니다.
    3.  **최종 묘지 안착 (`Exit Verify`)**: 실물 소멸이 교차 검증되면, 비로소 DB의 상태를 `XE_CLOSED_SIGNAL` (또는 수동/익절 등 상세 코드)로 마킹합니다.
*   **안전장치 (자가 치유)**: 만약 브로커 요청이 실패하거나(Requote 등), 네트워크가 끊겨 응답을 못 받더라도 상태는 `IN_TRANSIT`에 머물게 됩니다. 이후 시퀀스의 타임아웃 방어 메커니즘과 `Retries` 로직이 작동하여 다시 청산을 시도하거나 시스템에 알람을 울려 **좀비 포지션의 발생을 100% 차단**합니다.