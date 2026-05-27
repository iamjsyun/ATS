# 분석 보고서: 오더 접수 및 진입 가드(Guard) 조건 분석 (v1.0)

본 보고서는 거래 시스템(ATSE) 내에서 주문(Order)을 접수하고 실행하기 전에 수행하는 가드(Guard) 조건과 유효성 검증 체계를 분석하여 기술합니다.

---

## 1. 가드 시스템 설계 개요

시스템은 브로커에게 주문을 전송하기 전 발생할 수 있는 오류(예: 호가 불일치, 증거금 부족, 상호 충돌 등)를 미연에 방지하기 위해 **2단계 유효성 검증 가드 구조(Dual-Layer Validation)**를 채택하고 있습니다.

1. **기반 인프라 가드 (`CXGuard`)**: 식별 규칙, 심볼 가격 한계선, 최소/최대 로트 크기, 스탑레벨 준수 여부 등 거래 터미널 규격을 물리적으로 검증합니다.
2. **비즈니스 리스크 가드 (`CXTaskEntry_L_Validate`)**: SSOC(Single Source of Calculation) 원칙에 따라 실시간 마진 상태, 계좌 리스크 한계선, 중복 체결 정합성 등을 논리적으로 검증합니다.

---

## 2. 세부 가드(Guard) 조건 및 검증 규칙

오더 접수 시 적용되는 주요 가드 조건들을 네 가지 범주로 분류하여 상세히 기술합니다.

```
[ 주문 요청 유입 ]
        │
        ├── 1. 식별성 검증 (Magic Number, SID/GID 규격 검사)
        ├── 2. 심볼 제약 검증 (Volume Limit, StopsLevel 범위 체크)
        ├── 3. 리스크/마진 검증 (증거금 가용성, 계좌 드로우다운 검사)
        └── 4. 터미널 정합성 검증 (중복 주문 방지, 강제 청산 우회 체크)
        │
[ 브로커 전송 (Safe Placement) ]
```

### 2.1 식별성 및 프로토콜 무결성 검증 (Identity & Protocol)
* **Magic Number 검증 (`ValidateMagic`)**:
  * 주문에 포함된 매직넘버가 설정 파일(`ATSA.json` 로드값)에 등록된 Target Magic Number와 일치하는지 확인합니다. 등록되지 않은 알 수 없는 전략의 주문이 실행되는 것을 차단합니다.
* **SID/GID 길이 검증 (`ValidateSID` / `ValidateGID`)**:
  * **SID 규격**: `CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)-DIR(1)-TYPE(1)` 구조를 가진 **23자리** 문자열 포맷 준수 여부를 검사합니다.
  * **GID 규격**: `CNO(4)-YYMMDDHH(8)-SNO(2)-GNO(2)` 구조를 가진 **19자리** 문자열 포맷 준수 여부를 검사합니다.

### 2.2 심볼 및 시장 제약 검증 (Symbol & Market Constraints)
* **호가 제한 가격 검증 (`ValidatePrice`)**:
  * 지정가/역지정가 주문 가격이 브로커가 고시한 현재 세션의 가격 제한 최소 범위(`SYMBOL_SESSION_PRICE_LIMIT_MIN`) 및 최대 범위(`SYMBOL_SESSION_PRICE_LIMIT_MAX`) 이내에 위치하는지 검증합니다.
* **로트 크기 하한/상한 검증 (`ValidateLot`)**:
  * 거래하고자 하는 로트(Volume) 크기가 심볼의 최소 거래 단위(`SYMBOL_VOLUME_MIN`)보다 작거나, 최대 거래 단위(`SYMBOL_VOLUME_MAX`)보다 큰지 검사합니다.
  * *특이사항*: 만약 심볼의 거래 조건이 미로드되어 최대 로트가 `0` 이하로 조회될 경우, 강제로 Market Watch에 심볼을 등록하고 캐시를 갱신(Refresh)하여 재검증을 시도하는 복구 로직이 내장되어 있습니다.
* **스탑레벨 제약 준수 검증 (`ValidateStopLevel`)**:
  * 손절(SL) 및 익절(TP) 가격이 진입가 대비 최소한 **`StopsLevel + 1 Point`** 이상의 거리를 유지하고 있는지 검사합니다.
  * *목적*: 이 가드는 브로커에 주문을 전송할 때 발생하는 MQL5 `10015` (Invalid Expirations) 및 `10016` (Invalid Stops) 치명적 실행 에러를 원천 차단하는 역할을 합니다.

### 2.3 리스크 및 자산 관리 검증 (Risk & Margin Governance - SSOC)
이 검증은 전역 자산 제어 표준인 **SSOC 원칙**에 의해 반드시 `ICXRiskManager`와 `ICXPriceManager`를 통해서만 일관되게 처리됩니다.
* **로트 크기 정책 검증 (`riskMgr.ValidateLot`)**:
  * 주문 로트 크기가 시스템의 강제 한계 범위($0 < \text{Lot} \le 50.0$) 및 내부 리스크 관리 기준을 충족하는지 검증합니다.
* **가용 마진(증거금) 검사 (`CheckMarginAvailability`)**:
  * 현재 실시간 시장가(`priceMgr.GetMarketPrice`)를 기준으로 포지션 진입 시 요구되는 예상 증거금을 계산하고, 현재 계좌의 프리 마진(Free Margin) 잔고가 이를 감당할 수 있는지 검사합니다.
* **계좌 전체 리스크 검증 (`ValidateAccountRisk`)**:
  * 현재 계좌의 손실 금액(Drawdown)이나 활성 포지션들의 리스크 총량이 최대 허용치 한계를 초과했는지 최종 검사합니다.

### 2.4 터미널 상태 정합성 검증 (Terminal Integrity)
* **터미널 이중 진입 방지 (`ValidateTerminalIntegrity`)**:
  * 주문을 접수하기 전에, 이미 해당 SID를 가진 포지션이 거래 터미널(MT5) 상에 존재하거나 현재 전송 중(In-Transit)인지 세션 풀 및 터미널 상태를 확인하여 중복 주문(Double Spawning)을 사전 방지합니다.
* **강제 청산/에러 상태 감지 및 우회**:
  * 신호의 청산 의도가 활성화(`xa_exit == XA_ACTIVE`)되었거나 오류 상태(`xe_status == XE_ERROR`)인 경우 주문 접수를 즉시 중단(Abort)하고 해당 복구/에러 세션 상태로 리다이렉트합니다.

---

## 3. 기대 효과 및 아키텍처적 의의

1. **에러 원천 차단**: 브로커 서버로 통신 트래픽을 보내기 전 로컬 샌드박스에서 모든 제약을 사전 스캔하여, 에러 코드 `10015`, `10016` 등으로 인한 거래 체결 누수를 방지합니다.
2. **트레이딩 안전장치**: 시스템 오작동이나 잘못된 호가 전송으로 계좌 마진콜이 발생하는 것을 강력히 통제합니다.
3. **독립적인 결합 격리**: 가드 로직을 물리 규격(`CXGuard`)과 비즈니스 룰(`TaskEntry_L_Validate`)로 단절함으로써 거래 규정 변경 시 인프라 코드의 수정 없이 유연하게 안전장치 조건을 확장할 수 있습니다.
