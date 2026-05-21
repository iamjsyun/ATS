# ATS Master Testing & Simulation Guide (v1.0)

## 1. 개요 (Overview)
본 문서는 ATS 시스템의 무결성을 검증하기 위한 자율 시뮬레이터 설계, 가상 연동 테스트 전략 및 실전 매매 시나리오를 통합한 가이드이다.

---

## 2. ATSE 자율 시뮬레이터 설계 (Autonomous Simulator)

### 2.1 가상 클락 (Virtual Clock)
- **결정성(Determinism) 확보**: 모든 활성 세션의 태스크 처리가 완료된 후에만 시간을 1초 증가시키는 Step-Lock 프로토콜을 준수한다.
- **재현성**: 순차적(Sequential) 실행을 통해 테스트 결과를 100% 재현 가능하게 한다.

### 2.2 Mock Broker Layer (SSOC)
- **MockPriceManager**: CSV 시나리오 기반 Ask/Bid 생성 및 슬리피지 모델링.
- **VirtualInventoryManager**: 터미널 자산을 메모리 내에 가상화 관리.
- **MockSymbolManager**: 심볼 속성(StopsLevel, Spread 등) 로컬 제공.

---

## 3. XTA.Test 고도화 및 가상 연동 전략

### 3.1 시계열 기반 시나리오 (Time-Series Simulation)
- **CSV 문법 확장**: 
    - `AWAIT_STATE`: 특정 상태 도달 시까지 대기.
    - `ASSERT_FAIL/REJECTED`: 네거티브 테스트 검증.
    - `INJECT@N`: 특정 시간(초)에 이벤트 주입.

### 3.2 가상 ATSE(Mock Engine) 시나리오
실제 MT5 없이 ATSA 내에서 다음의 연동 시나리오를 검증한다.
- **3단계 청산 파이프라인**: Exit 요청 후 의도적 무시/지연 시 재시도 로직 검증.
- **부분 체결(Partial Fill)**: 주문 수량과 체결 수량이 다를 때의 DataManager 반영 및 잔량 처리.
- **좀비(Zombie) 신호**: 장시간 상태 응답이 없는 신호에 대한 타임아웃 처리.

---

## 4. 실전 매매 시나리오 가이드 (Practical Scenario)

| 단계 | 주요 액션 | 상태(xa_entry/xe_status) |
| :--- | :--- | :--- |
| **1. 신호 주입** | 외부 신호 수신 및 DB 저장 | 1 / 0 (READY) |
| **2. 엔진 감지** | Watcher 감지 및 세션 할당 | 1 / 0 (READY) |
| **3. 진입 실행** | SSOC 검증 ➔ 주문 송신 ➔ 티켓 확인 | 1 / 10 (EXECUTED) |
| **4. 트레일링** | 가격 개선 시 OrderModify 실행 | 1 / 10 (ACTIVE) |
| **5. 청산 요청** | 사용자/시스템 청산 명령 | xa_exit: 1 |
| **6. 청산 완료** | 실물 소멸 확인 ➔ DB 확정 | xa_exit: 2 / 20 (CLOSED) |

---

## 5. 검증 지표 (Success Criteria)
- CSV 정의 `Expected Status`와 SQLite 결과가 100% 일치해야 함.
- 모든 로그가 **v11.1 Standard** 규격에 맞게 생성되어야 함.
- 비정상 상태 전이 주입 시 시스템의 회로 차단기(Circuit Breaker) 작동 여부.

---
**Last Updated**: 2026-05-21
**Governance**: Master Testing Authority for ATS Projects.
