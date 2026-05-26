# Exit Scenario Addition & Response Strategy Report (v1.0)

## 1. 개요 (Executive Summary)
본 보고서는 ATSE (Active Trading State Engine)의 청산 처리 파이프라인 무결성을 보장하기 위해 기존 4대 시나리오(A: 정상 포지션 청산, B: 주문 즉시 취소, C: 유령 신호 정리, D: 레이스 컨디션 방어)를 넘어, **현업 실전 매매에서 발생할 수 있는 극단적인 4대 예외 시나리오**를 추가 설계하고 이에 대응하기 위한 정밀 시스템 전략을 정의한다.

이를 통해 통신 두절, 부분 체결, 터미널 임의 조작 등 최악의 환경에서도 시스템 오작동 없이 사용자 자산을 안전하게 보호한다.

---

## 2. 추가 예외 시나리오 설계 (Advanced Scenarios)

### 시나리오 E: 부분 체결 후 긴급 청산 (Partial Fill Liquidation)
* **상황**: 지정가 대기 주문(Limit/Stop)이 시장에 접수된 후 일부 수량만 체결(Partial Fill)된 찰나에 청산 명령(`xa_exit=1`)이 도달한 경우.
* **오류 리스크**: 동일한 신호 ID(`SID`)에 대하여 이미 오픈된 활성 포지션(Position)과 취소해야 할 잔여 대기 오더(Order)가 터미널 상에 동시에 공존하여 단일 티켓 처리 로직이 락에 걸림.
* **대응 전략**: 
  1. `CXExitManager`는 단일 티켓 클로즈가 아닌 `SweepBySid`를 강제 가동한다.
  2. 해당 `SID`를 코멘트로 공유하는 모든 포지션 및 주문 목록을 터미널에서 전수 스캔한다.
  3. 잔여 대기 오더는 `OrderDelete`로 즉시 취소 처리하고, 체결된 포지션은 `PositionClose`로 시장가 청산한다.
  4. 모든 티켓 소멸을 재확인한 후 최종 `xe_status=20`을 갱신하고 세션을 종료한다.

### 시나리오 F: 브로커 오프라인/통신 장애 시 청산 지연 (Broker Disconnect Recovery)
* **상황**: 급격한 변동성이나 네트워크 물리 단절로 인해 브로커 서버와의 연결이 끊긴 상태에서 청산 명령(`xa_exit=1`)이 수신된 경우.
* **오류 리스크**: 브로커 송신 API(`OrderSend`) 호출 시 `10006 (Re-connect)` 또는 `10014 (Invalid request)` 거절코드가 발생하여 청산되지 않고 세션이 에러(`XE_ERROR`)로 동결됨.
* **대응 전략 (Immediate Retry & Circuit Breaker)**:
  1. 통신 단절 감지 시 즉시 세션을 에러로 종료하지 않고, 청산 전용 리트라이 루프(Exit Retry Buffer)로 진입한다.
  2. 1초 간격으로 최대 30회(30초) 동안 지속적으로 청산 송신을 재시도한다.
  3. 만약 30초 내에 연결이 복구되어 청산이 완료되면 정상 완료(`xe_status=20`) 처리한다.
  4. 30초 초과 시 회로 차단기(Circuit Breaker)를 발동하여 시스템의 모든 신규 진입을 전면 차단하고 대시보드에 긴급 경고(`BROKER_DISCONNECT_EXIT_FAIL`)를 출력한다.

### 시나리오 G: 다중 좀비 신호 적체 시 일괄 청산 (Massive Zombie Re-sweep)
* **상황**: 장시간 네트워크 장애나 DB 락이 해제된 직후, 적체되어 있던 다량의 좀비 자산들이 한꺼번에 청산 의도(`xa_exit=1`)로 인입되는 경우.
* **오류 리스크**: SQLite DB의 쓰기 쓰레드 병목 및 브로커 API 큐(Queue) 대기로 인해 순차 처리 시 병목이 발생하여 자산 손실 유발.
* **대응 전략 (Parallel Asynchronous Sweep)**:
  1. `CXSignalWatcher`는 `xa_exit=1`인 신호들을 다량 발견 시 개별 세션의 틱을 기다리지 않고 `Watcher` 수준에서 즉시 `SweepByMagic` 일괄 청산 스레드를 구동한다.
  2. 터미널 스캐너가 해당 Magic 넘버를 가진 모든 활성 자산을 어레이로 덤프한 뒤 비동기 벌크 명령으로 한 번에 브로커 서버로 취소/청산 명령을 방출한다.
  3. 벌크 명령 전송 성공 후 DB 상태를 한 번의 트랜잭션으로 묶어 일괄 `xe_status=20`으로 마킹한다.

### 시나리오 H: 터미널 실물 SL/TP 임의 조작 후 청산 (Manual SL/TP Drift Scenario)
* **상황**: 사용자가 모바일 MT5나 타 PC 터미널에서 포지션의 손절가(SL) 또는 익절가(TP)를 임의로 수정/삭제한 상태에서 청산 명령이 인입된 경우.
* **오류 리스크**: 메모리 상의 `XSignal` 캐시 데이터와 실제 브로커 서버의 SL/TP 정보 불일치로 청산 요청 검증 오류 유발.
* **대응 전략 (Pre-Close Shadowing)**:
  1. `CXExitManager`는 청산 패킷을 조립하기 직전, `ICXInventoryManager::SyncToSignal`을 강제 1회 호출한다.
  2. 실물 터미널 포지션 정보를 리스캔하여 메모리 내 `XSignal`의 SL, TP, Volume 정보를 실물과 100% 동기화시킨다.
  3. 동기화된 실물 정보를 기준으로 클로즈 주문을 송신하여 레이스 컨디션 및 매칭 에러를 원천 제거한다.

---

## 3. 종합 예외 대응 아키텍처 매트릭스

| 시나리오 | 검출 지점 | 핵심 대응 기술 (Core Tech) | 최종 상태 (State) |
| :--- | :--- | :--- | :--- |
| **A. 정상 포지션 청산** | `Task_IntentWatch` | `PositionClose` | `XE_CLOSED_SIGNAL (20)` |
| **B. 주문 즉시 취소** | `Step_Executing / IntentWatch` | `OrderDelete` | `XE_CLOSED_SIGNAL (20)` |
| **C. 유령 신호 정리** | `Step_Validation` | `Fast-Pass` (세션 스킵) | `XE_CLOSED_SIGNAL (20)` |
| **D. 레이스 컨디션 방어**| `Step_Spawning` | `Double-Check / Session Skip` | `XE_CLOSED_SIGNAL (20)` |
| **E. 부분 체결 긴급 청산**| `Exit_R_Order` | `Massive SweepBySid` (벌크 취소+청산) | `XE_CLOSED_SIGNAL (20)` |
| **F. 브로커 오프라인** | `CXTerminalPlatform` | `Exit Retry Loop & Circuit Breaker` | `XE_ERROR (99) / EMERGENCY` |
| **G. 다중 좀비 적체** | `CXSignalWatcher` | `Parallel Asynchronous Bulk Sweep`| `XE_CLOSED_SIGNAL (20)` |
| **H. SL/TP 임의 조작** | `Exit_R_Order` | `Pre-Close Shadowing Sync` | `XE_CLOSED_SIGNAL (20)` |

---
**문서 버전**: v1.0 (PDCA/Design Storage Standard 준수)
**작성 주체**: Antigravity AI Coding System
**승인 상태**: 최초 작성 및 검토 대기
