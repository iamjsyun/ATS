# ATSE Autonomous Simulator & Unit Test Design (v1.0)

**날짜**: 2026-05-21
**상태**: 설계 확정 (Approved)
**대상**: ATSE (MQL5)

## 1. 개요 (Overview)
본 문서는 MT5 터미널 없이도 ATSE의 하이퍼-원자적(Hyper-Atomized) 태스크를 독립적으로 검증하기 위한 자율 시뮬레이터의 설계를 정의한다. 결정성(Determinism) 확보를 위해 가상 클락(Virtual Clock)과 단계별 잠금(Step-Lock) 프로토콜을 도입한다.

## 2. 핵심 아키텍처 (Core Architecture)

### 2.1 Virtual Clock (Master Control)
- **역할**: 시스템 시간(`TimeCurrent()`)의 주권을 가짐.
- **동작**: 모든 활성 세션의 태스크 처리가 완료된 후(TASK_YIELD/BREAK)에만 시간을 1초 증가시킨다.
- **인터페이스**: `IVirtualClock`을 통해 시간 데이터를 통합 관리한다.

### 2.2 Mock Broker Layer (SSOC)
- **MockPriceManager**: CSV 시나리오 또는 설정된 변동폭에 따라 가사 Ask/Bid 가격을 생성한다. 슬리피지(Slippage) 확률 모델을 내장한다.
- **VirtualInventoryManager**: 터미널의 포지션/오더 리스트를 메모리 내에 가상화하여 관리한다.
- **MockSymbolManager**: StopsLevel, Spread, LotStep 등 심볼 속성을 로컬 데이터로 제공한다.

### 2.3 Signal Injection System
- **Input**: CSV 파일 (`test_suite.csv`).
- **Flow**: CSV 로더가 신호 정보를 읽어 SQLite DB의 `Signal` 테이블에 `xa_entry=1` 상태로 직접 주입한다.
- **Detection**: `SignalWatcher`가 SQLite를 폴링하여 신호를 감지하고 세션을 생성한다.

## 3. 테스트 전략 (Testing Strategy)

### 3.1 결정성 보장 (Determinism)
- **Sequential Execution**: 멀티 쓰레드 경쟁 대신 순차적 실행을 통해 테스트 결과의 재현성을 100% 확보한다.
- **Step-Lock Protocol**: `Tick 생성 -> 태스크 실행 -> 상태 검증 -> 시간 진행` 순서의 엄격한 루프를 준수한다.

### 3.2 Failure Injection (결함 주입)
- **DB Lock 시뮬레이션**: `MockRepository`를 통해 의도적으로 DB 쓰기 실패를 발생시켜 재시도 로직의 안정성을 검증한다.
- **Broker Error 시뮬레이션**: 주문 전송 시 특정 리턴 코드(예: 10016, 4756)를 강제 주입하여 세션의 회로 차단기(Circuit Breaker)가 정상 작동하는지 확인한다.

## 4. 검증 지표 (Success Criteria)
- CSV에 정의된 `Expected Status`와 `Expected Price`가 최종 SQLite 레코드와 100% 일치해야 한다.
- 모든 트레이딩 로그 프리픽스(v10.4 Standard)가 규격에 맞게 생성되어야 한다.

---
**Last Updated**: 2026-05-21
**Governance**: Shared via _doc folder for cross-project alignment.
