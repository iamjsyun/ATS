# 설계 규격서: CXTradeTest 프로젝트 고도화 및 테스트 시나리오 언어(TCL) 설계 (v1.0)

본 설계서는 ATSE 트레이딩 엔진의 하이퍼-원자적 상태 및 시퀀스 무결성을 효율적으로 검증하기 위해, `CXTradeTest` 통합 테스트 환경을 고도화하고 테스트 시나리오 정의 전용 언어인 **TCL(Test Scenario Language)**의 문법, 동작 모델, 결과 평가 엔진 및 결정론적 가상 가격 생성기의 세부 기능을 규정합니다.

---

## 1. 테스트 시나리오 언어 (TCL: Test Scenario Language) 설계

TCL은 기존 CSV 방식의 단순 레코드 형태를 탈피하여, 테스트 시나리오의 흐름, 주입 조건, 검증 조건을 선언적으로 정의할 수 있는 커스텀 도메인 언어입니다.

### 1.1 TCL 기본 문법 및 기호 규격
TCL은 오케스트레이터의 시맨틱 DSL과 유사한 구분 기호(`>`, `?`, `:`, `!`, `@`, `~`, `*`)를 공유하여 학습 곡선을 최소화하고 일관성을 보존합니다.

```tcl
# [주석] 샵(#) 기호로 시작하는 줄은 주석 처리
SCENARIO: [시나리오_유니크_ID] : "시나리오 설명 문자열"

# 1. 초기 정의부 (Definition Phase)
DEFINE: SYMBOL=EURUSD, CNO=1001, SNO=1, LOT=0.1

# 2. 가격 생성기 설정 (Market Feed Phase)
PRICER: EURUSD > GBM : drift=0.0001, volatility=0.001, start=1.0950, spread=2

# 3. 테스트 시퀀스 가동 (Step-Lock Pipeline Phase)
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, price_signal=1.0950, \
                              cno=1001, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0, \
                              lot=0.1, lot_strategy=1, lot_value=10000, lot_rate=0.01, \
                              te_start=10, te_step=5, te_limit=50, \
                              ts_start=15, ts_step=5, sl=100, tp=150
          ? EXPECT: session : state=ORD_READY

TICK: 2   > MARKET: EURUSD  : tick_count=1  # 1 tick 가격 생성 및 피딩
          ? EXPECT: session : state=ORD_EXECUTING

TICK: 5   > MARKET: EURUSD  : price=1.0945  # 수동 가격 강제 주입
          ? EXPECT: session : state=ORD_PENDING ! FAIL_MSG: "체결 오더 대기 실패"

TICK: 10  > INJECT: terminal: order_fill=true, ticket=12345
          ? EXPECT: session : state=POS_ACTIVE * xe_status=XE_EXECUTED

TICK: 20  > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=POS_LIQUIDATING * xe_status=XE_CLOSED_SIGNAL

TICK: 21  > MARKET: EURUSD  : price=1.0965
          ? EXPECT: session : state=SYS_CLOSED
```

### 1.2 의미 기호 매핑 정의
- `SCENARIO:` : 테스트 시나리오의 고유 영역 정의 및 선언
- `DEFINE:` : 테스트 전역에서 참조할 매개변수 바인딩
- `PRICER:` : 가상 가격 생성기 바인딩 및 파라미터 초기화
- `TICK:` : 가상의 가상 클록(Step-Lock Virtual Clock)의 트리거 포인트 지정
- `>` : 동작(Action) 지시 접두어 (`INJECT`, `MARKET`, `PRICER` 등)
- `:` : 주입 속성 리스트 정의 (Key-Value 쌍)
- `?` : 검증 조건(Expectation) 접두어
- `!` : 검증 실패 시 보고서에 출력할 에러 메시지 지정
- `*` : 글로벌 시스템 파라미터 (`xe_status` 등) 검증 조건

---

## 2. DSL과의 형식 유사성 검토

오케스트레이터의 시퀀스 DSL과 테스터의 TCL은 구조적으로 동일한 **상태-동작-조건 파이프라인** 모델을 공유합니다.

| 차원 (Dimension) | Sequence DSL (실행 엔진 제어) | Test Scenario TCL (검증 엔진 제어) |
| :--- | :--- | :--- |
| **선언 주체** | `AppOrchestrator` | `CXScenarioRunner` / `TCL 파일` |
| **흐름 시작 (`>`)** | 실행할 스텝명 (`EntryDiscovery` 등) | 동작 유형 (`INJECT`, `MARKET`) |
| **상태 정의** | 시퀀스 전이 대상 (`ORD_READY` 등) | 가상 틱 카운트 및 주입 대상 테이블 지정 |
| **파라미터 (`:`)** | 복합 단계에 묶인 실행 Task 리스트 | 주입 데이터 명세 (`xa_entry=1` 등) |
| **조건부 처리 (`?`)** | 성공 시 전이 상태 지정 | 검증 기대 조건 (`EXPECT` 상태 및 값) |
| **예외 처리 (`!`)** | 실패 시 전이 상태 지정 | 검증 실패 시 에러 보고서 포맷팅 메시지 |
| **시간 인자 (`@`)** | 타임아웃 초 및 재시도 횟수 지정 | 가상 틱 가속화 및 스텝 잠금 지연 시간 |
| **추가 속성 (`*`)** | 분기(Branch)를 유도할 내부 상태 가드 | 런타임 변수 동시 충족 조건 가드 |

---

## 3. 시나리오 주입값 및 기대값 정의 규격

### 3.1 주입값 (INJECT) 명세 규격
주입 데이터는 DB 레코드(TCL-signals)와 MT5 터미널 환경(TCL-terminal)의 두 가지 가상 계층으로 분리하여 모의(Mocking)합니다.

#### 1) `INJECT: signals` (DB 주입)
- `xa_entry` : 진입 시그널 플래그 (0: RAW, 1: ACTIVE)
- `xa_exit` : 청산 시그널 플래그 (0: RAW, 1: ACTIVE, 2: COMP)
- **SID 구성 요소**:
  - `cno` : 채널 번호 (예: 1001)
  - `yymmddhh` : 생성 시간 식별자 (예: 26052704)
  - `sno` : 시그널 일련번호 (예: 01)
  - `gno` : 그리드 일련번호 (예: 01)
  - `dir` : 주문 방향 (1: BUY, 2: SELL)
  - `type` : 주문 유형 (0: MARKET, 1: LIMIT, 2: STOP)
- **자금 관리 (Lot Options)**:
  - `lot` : 주문 기본 수량
  - `lot_strategy` : 로트 계산 전략 유형 (예: 고정 로트, 비율 로트 등)
  - `lot_value` : 로트 계산을 위한 기준값 (자산 크기 등)
  - `lot_rate` : 리스크 비율 계수 (예: 0.01 = 1%)
- **트레일링 진입 (TE Options)**:
  - `te_start` : 진입 추격 시작 오프셋 포인트
  - `te_step` : 진입 추격 이동 간격 포인트
  - `te_limit` : 진입 추격 허용 한계 포인트
- **트레일링 스탑 (TS Options)**:
  - `ts_start` : 익절 추격 시작 트리거 포인트
  - `ts_step` : 익절 추격 이동 간격 포인트
- **손절/익절 (SL/TP)**:
  - `sl` : 손절 포인트 (Stop Loss Points)
  - `tp` : 익절 포인트 (Take Profit Points)
- `price_signal` : 시그널 가격

#### 2) `INJECT: terminal` (터미널 모의 주입)
- `order_fill` : `true` 설정 시 터미널 내 대기 오더를 삭제하고 활성 포지션을 생성하여 체결을 재현.
- `order_cancel` : 대기 오더가 삭제(Cancel)된 환경을 모의.
- `ticket` : 모의 생성할 오더/포지션의 티켓 번호 지정.

### 3.2 기대값 (EXPECT) 검증 규격
기대값은 시나리오 기획 상태와 DB 물리 상태를 교차 검증합니다.
- `session: state` : `ORD_READY`, `POS_ACTIVE` 등 internal 세션 상태 일치 검증.
- `xe_status` : DB 내 저장된 물리 실행 상태 코드(0, 5, 10, 20, 24 등) 일치 검증.
- `ticket` : `ticket>0` 또는 `ticket=12345` 등의 티켓 생성 유무 검증.

---

## 4. 테스트 결과 보고서 및 추적 파이프라인

검증 엔진은 테스트 실행 중 발생하는 모든 전이 및 이벤트를 파이프라인 형태로 실시간 추적하고 결과를 평가합니다.

### 4.1 시나리오 경과 파이프라인 추적 기록 (Trace Log)
테스트 구동 시 Virtual Clock 틱별로 아래 규격의 추적 로그가 구조화되어 메모리에 기록되고 보고서 파일로 출력됩니다.

```json
{
  "scenario_id": "SCEN_GOLDEN_PATH_01",
  "pipeline_traces": [
    {
      "virtual_tick": 1,
      "elapsed_virtual_sec": 1,
      "action": "INJECT_SIGNAL",
      "state_before": "NONE",
      "state_after": "ORD_READY",
      "db_xe_status": 0,
      "db_xa_entry": 1,
      "verification": "PASS"
    },
    {
      "virtual_tick": 2,
      "elapsed_virtual_sec": 2,
      "action": "MARKET_TICK_FEED",
      "price_ask": 1.0952,
      "price_bid": 1.0950,
      "state_before": "ORD_READY",
      "state_after": "ORD_EXECUTING",
      "verification": "PASS"
    }
  ]
}
```

### 4.2 평가 기준 (Evaluation Criteria)
- **PASS** : 모든 기대값(`EXPECT`) 검증이 에러 없이 일치하고, 가상 틱이 끝날 때까지 시퀀스가 터미널 수렴 상태(`SYS_CLOSED` 등)에 도달한 경우.
- **FAIL** : 특정 틱에서 `EXPECT` 값 불일치가 검출되거나, 시퀀스가 무한 루프 또는 지정된 타임아웃에 도달하여 전이가 멈춘 경우.
- **ABORT** : DB 연결 실패, 혹은 잘못된 TCL 파일 파싱 예외로 인해 실행 자체가 중단된 경우.

---

## 5. 가상의 가격 생성기 (Virtual Price Generator) 설계

가상의 가격 생성기는 실제 브로커 연결 없이도 트레이딩 세션의 트레일링 진입/익절 등의 로직을 결정론적으로 검증할 수 있도록 설계된 테스트용 시뮬레이션 물리 엔진입니다.

### 5.1 가격 생성기 세부 기능 규격

1. **결정론적 배열 피딩 (Deterministic Array Feeding)**:
   - 개발자가 설정한 고정 가격 시퀀스를 차례대로 공급하여 특정 호가 역전 현상 등을 재현합니다.
2. **수식 모델 기반 실시간 피딩 (Mathematical Real-time Feeding)**:
   - 기하 브라운 운동, 평균 회귀 모델 등을 활용해 난수 기반으로 틱을 자율 생성합니다.
3. **가상 스프레드 결합 (Bid/Ask Integration)**:
   - 생성된 원천 가격(Mid Price)에 설정된 스프레드 포인트 값을 곱해 `ASK` 및 `BID` 가격을 동시 연산하여 `SymbolInfoTick` 모의 함수에 공급합니다.

### 5.2 가상 가격 생성기 모델별 수식 및 매개변수 규격

#### 1) 기하 브라운 운동 (GBM: Geometric Brownian Motion)
추세성 시장 및 일반적인 변동성 환경을 모사할 때 사용합니다.
$$\Delta S_t = \mu S_t \Delta t + \sigma S_t \epsilon \sqrt{\Delta t}$$
- $S_t$ : 현재 가격
- $\mu$ (`drift`) : 드리프트 파라미터 (가격의 평균적인 상승/하락 추세)
- $\sigma$ (`volatility`) : 변동성 계수 (난수 가격 흔들림 강도)
- $\epsilon$ : 표준 정규 분포 상의 정규 난수 ($N(0,1)$)
- $\Delta t$ : 시간 증분 (Virtual Tick 간격)

#### 2) 평균 회귀 모델 (OU: Ornstein-Uhlenbeck Process)
횡보 장세, 레인지 그리드 검증, 또는 극단적 변동 후 원점 회귀 테스트 시 사용합니다.
$$\Delta x_t = \theta (\mu - x_t) \Delta t + \sigma \epsilon \sqrt{\Delta t}$$
- $x_t$ : 현재 가격
- $\theta$ (`mean_reversion_speed`) : 평균 회귀 속도 (가격이 평균값으로 당겨지는 복원력 세기)
- $\mu$ (`mean_price`) : 장기 평균 가격 (회귀의 중심선)
- $\sigma$ (`volatility`) : 확산 변동성
- $\epsilon$ : 정규 난수

#### 3) 트렌드 점프 모델 (Trend + Spike Process)
뉴스 발표 시의 강한 슬리피지, 휩소, 급격한 손절 및 청산 프로세스를 모의합니다.
$$S_t = S_0 + \alpha t + J_t$$
- $\alpha$ (`trend_slope`) : 선형 시간 추세 기울기
- $J_t$ (`jump_process`) : 푸아송 과정을 따르는 점프 분포. 특정 시점 도달 혹은 일정 확률 발생 시 큰 폭의 불연속적인 가격 스파이크(Spike) $H \cdot Y_i$ 발생 ($H$: 점프 방향, $Y_i \sim N(\mu_J, \sigma_J^2)$: 점프 강도).

- `Spread` : 설정된 고정 스프레드 (Point 단위)
- `Point` : 대상 심볼의 최소 변화 수치 (예: EURUSD의 경우 `0.00001`)

---

## 6. 핵심 검증 시나리오 TCL 정의 예시 (Core Test Scenarios in TCL)

### 6.1 시나리오 1: 수동 청산 (Manual Exit Fast-Track)
사용자가 MT5 모바일 앱 등으로 포지션을 강제 종료했을 때, 세션이 자산 소멸을 감지하여 즉시 `xe_status=24` 및 `SYS_CLOSED`로 종료 처리하는지 검증합니다.
```tcl
SCENARIO: SCEN_MANUAL_EXIT_01 : "수동 포지션 강제 종료 감지 및 Fast-Track 검증"
DEFINE: SYMBOL=EURUSD, CNO=1001, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. 포지션 활성화 상태 주입
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1001, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0, lot=0.1
TICK: 2   > INJECT: terminal: order_fill=true, ticket=55555
          ? EXPECT: session : state=POS_ACTIVE * xe_status=XE_EXECUTED

# 2. 터미널에서 포지션 수동 삭제 모의 (자산 증발)
TICK: 3   > INJECT: terminal: order_fill=false, ticket=0  # 실물 티켓 실종
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_MANUAL ! FAIL_MSG: "수동 종료 Fast-Track 감색 실패"
```

### 6.2 시나리오 2: 좀비 자산 처리 (Zombie/Orphan Asset Recovery)
DB에 시그널이 없거나 이미 종료되었으나 터미널에 실물 자산이 좀비 상태로 남아있을 때, 격리(`XE_QUARANTINED`) 후 강제 세션 수렴 처리하는 시나리오입니다.
```tcl
SCENARIO: SCEN_ZOMBIE_RECOVERY_01 : "좀비 자산 감지 및 격리/복구 시나리오 검증"
DEFINE: SYMBOL=EURUSD, CNO=1002, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. DB에는 없으나 터미널에 티켓이 존재하는 좀비 상태 생성
TICK: 1   > INJECT: terminal: order_fill=true, ticket=99999
          # Reverse Injector에 의해 fakeSig 생성 및 격리 상태 전이 기대
          ? EXPECT: session : state=POS_ACTIVE * xe_status=XE_QUARANTINED ! FAIL_MSG: "좀비 자산 격리 실패"
```

### 6.3 시나리오 3: SID 중복 주입 (Duplicate SID Injection)
동일한 SID를 가진 신호가 중복 주입되었을 때, 두 번째 신호 주입을 무시하고 기존 세션의 고유 무결성을 보존하는지 검증합니다.
```tcl
SCENARIO: SCEN_DUP_INJECT_01 : "동일 SID 중복 신호 주입 차단 검증"
DEFINE: SYMBOL=EURUSD, CNO=1003, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. 첫 번째 신호 주입
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, price_signal=1.0950, cno=1003, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
          ? EXPECT: session : state=ORD_READY

# 2. 동일한 SID를 가진 신호 재주입 시도
TICK: 2   > INJECT: signals : xa_entry=1, xa_exit=0, price_signal=1.0990, cno=1003, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
          # 시스템에 의해 중복 주입은 거부되고 기존 세션 상태 유지 기대
          ? EXPECT: session : state=ORD_READY ! FAIL_MSG: "중복 SID 오버라이드 오류 발생"
```

### 6.4 시나리오 4: 미존재 자산 청산 신호 주입 (Exit Intent for Non-existent Asset)
DB 상에는 신호가 있으나 실제 터미널 상에 대응하는 오더/포지션이 없는 가상 상태에서 청산 신호(`xa_exit=1`)가 접수되었을 때, 대기 없이 즉시 `SYS_CLOSED`로 종결 처리하는지 검증합니다.
```tcl
SCENARIO: SCEN_VOID_EXIT_01 : "미존재 자산에 대한 청산 요청 즉시 종결 검증"
DEFINE: SYMBOL=EURUSD, CNO=1004, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. 신호 주입 후 오더 대기 상태 진입 (실물 티켓 미등록)
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1004, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
          ? EXPECT: session : state=ORD_READY

# 2. 실물 자산이 없는 상황에서 청산 신호 주입
TICK: 2   > INJECT: signals : xa_exit=1
          # 터미널 스캔 결과 실물이 없으므로 즉시 Closed 처리 기대
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "미존재 자산 청산 대기 루프 발생"
```

### 6.5 시나리오 5: 대기 오더 청산 신호 주입 (Exit Intent for Pending Order in READY)
대기 오더 배치가 아직 완료되기 전 혹은 배치 직후 미체결 상태(`ORD_READY` / `ORD_PENDING`)에서 청산 신호(`xa_exit=1`)가 접수되었을 때, 오더를 취소하고 소멸 프로세스로 전환하는지 검증합니다.
```tcl
SCENARIO: SCEN_ORD_READY_EXIT_01 : "대기 오더 진입 전 청산 요청 취소 처리 검증"
DEFINE: SYMBOL=EURUSD, CNO=1005, SNO=01, GNO=01, DIR=1, TYPE=1 # LIMIT 주문

# 1. 신호 주입 및 대기 상태
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1005, yymmddhh=26052704, sno=01, gno=01, dir=1, type=1
          ? EXPECT: session : state=ORD_READY

# 2. 진입 실행 전 취소 요청 접수
TICK: 2   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "대기 오더 즉각 취소 실패"
```

### 6.6 시나리오 6: 대기 오더 진트 단계 청산 신호 주입 (Exit Intent during Trailing Entry)
진입 가격 추격(Trailing Entry) 상태인 `ORD_TRAILING` 루프 도중에 청산 신호(`xa_exit=1`)가 접수되었을 때, 추격을 즉시 멈추고 브로커의 대기 주문을 취소(`OrderDelete`)하여 `SYS_CLOSED`로 안전 수렴하는지 검증합니다.
```tcl
SCENARIO: SCEN_ORD_TRAILING_EXIT_01 : "진트(Trailing Entry) 수행 중 청산 신호 즉시 대응 검증"
DEFINE: SYMBOL=EURUSD, CNO=1006, SNO=01, GNO=01, DIR=1, TYPE=1

# 1. 대기 오더 체결 대기 및 트레일링 진입 구동
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1006, yymmddhh=26052704, sno=01, gno=01, dir=1, type=1, te_start=10, te_step=5
TICK: 2   > INJECT: terminal: ticket=77777 # 대기오더 번호 등록
          ? EXPECT: session : state=ORD_TRAILING

# 2. 트레일링 도중 청산 신호 유입
TICK: 3   > INJECT: signals : xa_exit=1
          # 대기 오더 삭제 처리 및 세션 소멸 기대
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "대기 오더 트레일링 중 취소 실패"
```

### 6.7 시나리오 7: 포지션 청산 신호 주입 (Active Position Liquidation)
포지션이 체결되어 단순 감시 모드(`POS_ACTIVE`)로 동작 중일 때 청산 신호(`xa_exit=1`)가 유입되면, 청산 단계(`POS_LIQUIDATING`)로 즉시 전이하여 터미널 포지션을 시장가 종료처리하고 `SYS_CLOSED`로 전환하는지 검증합니다.
```tcl
SCENARIO: SCEN_POS_ACTIVE_EXIT_01 : "활성 포지션 감시 중 청산 신호 전이 검증"
DEFINE: SYMBOL=EURUSD, CNO=1007, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. 포지션 체결 및 활성 감시 진입
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1007, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0
TICK: 2   > INJECT: terminal: order_fill=true, ticket=88888
          ? EXPECT: session : state=POS_ACTIVE

# 2. 청산 신호 주입
TICK: 3   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=POS_LIQUIDATING

# 3. 브로커 청산 체결 모의
TICK: 4   > INJECT: terminal: order_fill=false, ticket=0
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SIGNAL ! FAIL_MSG: "활성 포지션 시장가 청산 종결 실패"
```

### 6.8 시나리오 8: 포지션 익트 단계 청산 신호 주입 (Active Position Liquidation during Trailing Stop)
이익 보존을 위한 트레일링 스탑(`POS_TRAILING`) 루프를 수행하고 있는 도중 청산 신호(`xa_exit=1`)가 긴급 유입되었을 때, 익트 로직을 즉각 중단(Abort)하고 시장가 청산 단계로 우회 전이하는지 검증합니다.
```tcl
SCENARIO: SCEN_POS_TRAILING_EXIT_01 : "익트(Trailing Stop) 중 청산 신호 인터럽트 검증"
DEFINE: SYMBOL=EURUSD, CNO=1008, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. 포지션 체결 및 트레일링 스탑 진입
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1008, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0, ts_start=10, ts_step=5
TICK: 2   > INJECT: terminal: order_fill=true, ticket=11111
TICK: 3   > MARKET: EURUSD  : price=1.0970 # 익절선 돌파로 Trailing Stop 활성화 유도
          ? EXPECT: session : state=POS_TRAILING

# 2. 익트 도중 외부 청산 신호 유입
TICK: 4   > INJECT: signals : xa_exit=1
          ? EXPECT: session : state=POS_LIQUIDATING ! FAIL_MSG: "익트 중 청산 시그널 인터럽트 수신 실패"
```

### 6.9 시나리오 9: SL/TP 도달 청산 (Broker SL/TP Triggered Close)
포지션 유지 중 터미널의 가격 피드가 주입된 SL 또는 TP 단가를 이탈하여 브로커가 자동으로 포지션을 종료(`DEAL_REASON_SL` 또는 `DEAL_REASON_TP`)했을 때, 세션이 이를 감지하여 `XE_CLOSED_SL` 또는 `XE_CLOSED_TP`로 구분 종결하는지 검증합니다.
```tcl
SCENARIO: SCEN_BROKER_SL_TP_01 : "브로커 자동 SL 도달 청산 구분 판정 검증"
DEFINE: SYMBOL=EURUSD, CNO=1009, SNO=01, GNO=01, DIR=1, TYPE=0

# 1. 손절선(SL=50pt) 설정 포지션 진입
TICK: 1   > INJECT: signals : xa_entry=1, xa_exit=0, cno=1009, yymmddhh=26052704, sno=01, gno=01, dir=1, type=0, sl=50, tp=100, price_signal=1.0950
TICK: 2   > INJECT: terminal: order_fill=true, ticket=22222
          ? EXPECT: session : state=POS_ACTIVE

# 2. 가격 하락으로 손절 단가(1.0945) 터치 및 터미널 포지션 강제 삭제 (이유: SL 청산 모의)
TICK: 3   > MARKET: EURUSD  : price=1.0940
          > INJECT: terminal: order_fill=false, ticket=0
          # 결과 상태가 XE_CLOSED_SL (21)로 정밀 분기 매핑되는지 확인
          ? EXPECT: session : state=SYS_CLOSED * xe_status=XE_CLOSED_SL ! FAIL_MSG: "SL 도달 자동 청산 감지 실패"
```

