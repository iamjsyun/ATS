# [REPORT] estart 가격 라인 차트 표시 오류 및 진입 시퀀스 오류 정밀 분석 보고서 (v1.0)

본 보고서는 진입 트레일링(Trailing Entry, 이하 진트) 실행 중 차트 상에 `ESTART` (TE_START) 트리거 라인이 잘못된 위치에 그려지는 현상과, 매우 작은 `te_start` 설정값에서 진트 트레일링이 활성화되지 않고 지정가 대기 오더 가격에서 즉시 체결(시장가 포지션 진입)되는 시퀀스 오류의 근본 원인을 정밀 분석하고 이에 대한 해결 방안을 제안합니다.

---

## 1. 개요 및 관련 파라미터 정의
진트 기능에 사용되는 핵심 파라미터와 가격 기준은 다음과 같습니다.
* **기준 시장가 (`price_signal`)**: 최초 신호 주입 시점의 시장가 (예: `$2350.00`).
* **대기 오더 가격 (`price_open` / `LIMIT`)**: 최초에 브로커에 접수하는 지정가 주문 가격. 기준 시장가 대비 **`ELIMIT`** (TE_LIMIT) 포인트만큼 유리한 방향으로 이격되어 배치됨 (예: 매수 주문은 `$2345.00`).
* **진트 활성화 임계치 (`TE_START` / `ESTART`)**: 대기 오더 접수 후, 시장가가 이 수준까지 도달했을 때 비로소 진트(추격)를 활성화하는 기준 포인트 (예: `300pt`, `$2347.00` 도달 시 활성화).
* **반등 진입 임계치 (`TE_STEP` / `ESTEP`)**: 진트가 활성화된 이후, 시장 극점(최저점/최고점) 대비 반대 방향으로 반등할 때 시장가로 진입하는 기준 포인트 (예: `100pt`, 최저점 `$2330.00` 대비 `$2331.00` 반등 시 진입).

---

## 2. 결함 분석 (Defect Analysis)

### 2.1 결함 1: 차트 트리거 라인의 방향 부호(Direction Sign) 반전 및 위치 오류
* **오류 지점**: 
  1. [CXTaskEntry_P_Finalize.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Entry/CXTaskEntry_P_Finalize.mqh#L40): 초기 오더 접수 직후 라인 생성 시.
  2. [CXTaskPending_L_Improve.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Improve.mqh#L71): 극점 추격 및 실시간 타이머 갱신 시.
* **현상**:
  - 매수(BUY) 지정가 오더의 경우, 가격이 하락할 때 진트가 활성화되어야 하므로 `ESTART` 활성화 라인은 대기 오더 가격(`$2345.00`)보다 **위(Positive, 현재가 쪽인 `$2347.00`)**에 그려져야 합니다.
  - 그러나 현재 수식은 다음과 같이 작성되어 있습니다:
    ```mql5
    // CXTaskEntry_P_Finalize.mqh (dir_sign = -1.0 for BUY)
    double triggerLine = orderPrice + (sig.GetTEStart() * point * dir_sign); // $2345.0 + (300 * 0.01 * -1.0) = $2342.0
    
    // CXTaskPending_L_Improve.mqh (dir_sign = -1.0 for BUY)
    double triggerPrice = extVal + (sig.GetTEStart() * point * dir_sign); // extVal - 300pt
    ```
  - 이로 인해 **매수(BUY)** 주문 시 트리거 라인이 대기 오더 가격보다 더 **아래(Negative, `$2342.00`)**에 그려집니다. 시장가가 `$2345.00`에 도달하면 브로커에 의해 지정가 오더가 즉시 체결되므로, 시장가는 `$2342.00`에 도달할 수 없습니다. 따라서 활성화 라인이 터치되지 않는 모순이 발생합니다.
  - **매도(SELL)** 주문의 경우도 반대로 대기 오더 가격보다 더 **위(Positive)**에 그려져 실제 시장가가 도달할 수 없는 영역에 위치합니다.

### 2.2 결함 2: 활성화 전(Phase 1)과 활성화 후(Phase 2) 차트 표시 기준의 혼선
* **상황**:
  - 진트가 활성화되기 전에는 **"진트 활성화 기준선"**(`price_signal +/- TE_START * point`)을 표시해야 합니다.
  - 진트가 활성화된 후(극점을 추격하는 상태)에는 시장이 실제로 반등할 때 진입하는 **"반등 진입 트리거선"**(`extreme -/+ TE_STEP * point`)을 표시해야 트레이더가 진입 직전 상황을 직관적으로 인지할 수 있습니다.
* **문제점**:
  - 현재 시각화 로직은 구분이 없이 상시 `TE_START` 파라미터와 극점(`extVal`)을 사용하여 `extVal + TE_START` 형태로 계산하고 있어, 실제 시장가 진입 기준점인 `TE_STEP` 반등가와 차트 라인이 일치하지 않는 왜곡이 발생합니다.

### 2.3 결함 3: 진트 활성화 가드(Guard) 부재로 인한 조기 시장가 진입 오류
* **오류 지점**: [CXTaskPending_L_Rebound.mqh](file:///d:/Projects/ATS/ATSE/CXTrade/Session/Workflow/Pending/CXTaskPending_L_Rebound.mqh#L43)
* **원인**:
  - 현재 코드에는 "진트가 활성화되었는지" 여부를 판단하는 상태 가드(State Guard)가 존재하지 않습니다.
  - 대기 오더가 접수된 직후, `CXTaskPending_L_Extreme`에 의해 극점(`extreme`)이 현재 시장가(`$2350.00`)로 초기화됩니다.
  - 이 상태에서 시장가가 `TE_START` (예: 50pt) 가격에 도달하여 진트가 정식 활성화되기도 전에, 시장가가 반대 방향으로 단 `TE_STEP` (예: 30pt) 만큼 튀어 오르면(예: `$2350.30` 도달), `CXTaskPending_L_Rebound`에서 반등 조건을 충족한 것으로 오판하여 즉시 대기 오더를 취소하고 시장가 포지션 진입을 실행합니다.
  - 이로 인해 `te_start` 값을 매우 작게 설정하거나 틱 변동이 심할 때, 진트 하락 추격이 시작되기도 전에 원래 오더 접수가 주변에서 자동으로 즉시 시장가 진입이 완료되는 시퀀스 오류가 발생합니다.

---

## 3. 해결 방안 및 작업 계획 (Correction Plan)

### 3.1 [단계 1] 진트 활성화 상태 레지스트리 도입 (ICXContext 활용)
진트가 공식 활성화되기 전까지는 반등 감지(`Rebound`) 및 가격 개선(`Improve`)이 동작하지 않도록 명확한 상태 플래그를 관리합니다.
* **활성화 판단 기준**:
  - **BUY**: `currentPrice <= price_signal - TE_START * point` (또는 `price_open + (TE_LIMIT - TE_START) * point` 미만으로 하락 시)
  - **SELL**: `currentPrice >= price_signal + TE_START * point` (또는 `price_open - (TE_LIMIT - TE_START) * point` 이상으로 상승 시)
* **상태 플래그 키**: `"TE_Active_" + sig.GetSid()`

### 3.2 [단계 2] 각 상태별 차트 라인 수식 정밀 교정
* **진트 활성화 전 (`TE_Active` = 0)**:
  - 차트 라인은 고정된 **진트 활성화 임계 가격**을 표시합니다.
  - **BUY**: `price_signal - (sig.GetTEStart() * point)`
  - **SELL**: `price_signal + (sig.GetTEStart() * point)`
  - 수식 단일화: `triggerPrice = price_signal + (sig.GetTEStart() * point * dirSign)` (여기서 `dirSign`은 BUY: `-1.0`, SELL: `1.0`)
* **진트 활성화 후 (`TE_Active` = 1)**:
  - 차트 라인은 극점 기준 실시간 **반등 진입 목표 가격**을 표시합니다.
  - **BUY**: `extreme + (sig.GetTEStep() * point)`
  - **SELL**: `extreme - (sig.GetTEStep() * point)`
  - 수식 단일화: `triggerPrice = extreme - (sig.GetTEStep() * point * dirSign)`

### 3.3 [단계 3] 관련 코드 수정 내역 (예정)

#### 1) `CXTaskEntry_P_Finalize.mqh`
* 최초 대기 오더가 접수되는 시점이므로 아직 활성화 전 상태입니다. 따라서 `price_signal` 기준의 활성화 목표 가격을 그려줍니다.
```mql5
// [v16.23 Initial Visual] 대기 오더 접수 직후 활성화 트리거 라인 생성
double priceSignal = sig.GetPriceSignal();
if(priceSignal <= 0) priceSignal = orderPrice - (sig.GetTELimit() * point * dir_sign); // price_signal 복원

double triggerLine = priceSignal + (sig.GetTEStart() * point * dir_sign);
CXChartVisualizer::DrawTEStart(sig, triggerLine);
```

#### 2) `CXTaskPending_L_Extreme.mqh` 및 `CXTaskPending_L_Rebound.mqh`
* `Rebound` 태스크의 최상단에서 활성화 플래그를 검증합니다.
* 활성화 조건이 아직 충족되지 않았다면 즉시 `TASK_CONTINUE`로 넘어가며, 활성화 조건이 충족되는 순간 컨텍스트에 활성화 마킹을 설정하고 극점 추적을 초기화합니다.

#### 3) `CXTaskPending_L_Improve.mqh`
* 활성화 여부에 따라 트리거 라인의 계산 방식을 동적으로 전환합니다.
```mql5
bool isActive = false;
ICXParam* pActive = ctx.GetParam("TE_Active_" + sig.GetSid());
if(IS_VALID(pActive) && pActive.GetInt() == 1) isActive = true;

double triggerPrice = 0;
if(!isActive) {
    // 1. 활성화 전: 활성화 기준선 표시
    double priceSignal = sig.GetPriceSignal();
    if(priceSignal <= 0) priceSignal = orderPrice - (sig.GetTELimit() * point * dir_sign);
    triggerPrice = priceSignal + (sig.GetTEStart() * point * dir_sign);
} else {
    // 2. 활성화 후: 극점 기준 실제 시장가 진입 트리거선 표시
    triggerPrice = extVal - (sig.GetTEStep() * point * dir_sign);
}
CXChartVisualizer::DrawTEStart(sig, triggerPrice);
```

---

## 4. 기대 효과
1. **차트 시각화 왜곡 해결**: 트레이더는 차트 상에서 파란색 실선이 시장 가격 흐름(하락/상승)에 따라 올바른 가이드라인 역할을 수행하는 것을 눈으로 직접 확인 가능합니다.
2. **진입 오동작 방지**: `te_start` 설정값의 대소 관계에 왜곡이 생기거나 미세한 노이즈 틱에 의해 주문 직후 원하지 않는 지정가 가격에서 시장가로 바로 넘어가 버리는 이상 진입 현상을 완벽히 차단합니다.
