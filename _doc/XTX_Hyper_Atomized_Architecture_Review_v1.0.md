# XTX Hyper-Atomized Architecture Review v1.0

## 1. 설계 철학 (Design Philosophy)
본 고도화 안은 MQL5 환경에서 시스템의 **결합도(Coupling)**를 최소화하고, 외부 환경(Broker, SQLite)의 불안정성에 대해 **격리된 실패 지점(Isolated Failure Domains)**을 구축하는 것을 목표로 함.

## 2. 핵심 아키텍처 원칙 (Core Principles)

### 가. 무상태 태스크 (Statelessness)
- 태스크는 내부 상태를 보관하지 않으며, 오직 `ICXParam` 컨텍스트를 통해서만 데이터를 릴레이함.
- 동일한 입력을 받으면 항상 동일한 판단 결과를 반환하는 순수 함수적 성격을 지향함.

### 나. 의도 기반 실행 (Intent-Based Execution)
- 실행(Execution)과 확정(Commit)을 분리함.
- `L-Layer`(판단) -> `P-Layer`(의도 기록) -> `R-Layer`(물리적 요청) -> `V-Layer`(물리적 확인) -> `P-Layer`(최종 확정) 순으로 진행.

### 다. 비차단 재시도 (Non-blocking Retries)
- 특정 태스크가 지연(응답 대기)될 경우, 전체 루프를 멈추지 않고 `TASK_YIELD` 상태를 반환하여 다음 시퀀스 틱에서 재진입하도록 설계.

## 3. 원자적 파이프라인 구조 (Atomized Pipeline)

### 1단계: 판단 (Decision)
- **로직 고립**: 터미널이나 DB 연결 없이 메모리 내 데이터만으로 진입/청산 조건 계산.
- **테스트 용이성**: 환경 변수 없이 로직 유닛 테스트 가능.

### 2단계: 선언적 잠금 (Declarative Locking)
- **중복 방어**: 실제 브로커 명령 송신 전, DB에 "현재 처리 중"임을 선언.
- **Race Condition 방지**: 다중 세션 환경에서 동일 자산에 대한 충돌 방지.

### 3단계: 물리적 트랜잭션 (Physical Transaction)
- **브로커 통신**: `OrderSend` 등 실제 자산 변동 명령 송신.
- **Ticket Shadowing**: 리턴된 티켓을 즉시 DB에 기록하지 않고, 메모리 컨텍스트에서 검증 단계를 거침.

### 4단계: 소멸 및 확정 (Absence & Finalization)
- **L3 검증**: 청산 시 터미널에서 자산이 완전히 소멸했는지 3회 이상 재조회 확인.
- **영속화**: 실물 확인이 끝난 데이터만 DB `signals_history` 또는 최종 상태로 기록.

## 4. 리스크 및 트레이드오프 (Risks & Trade-offs)
- **복잡성 증가**: 클래스 수 급증에 따른 파일 관리 오버헤드.
- **성능 고려**: SQLite Write 횟수 증가 가능성 -> `P-Layer`에서 불필요한 중복 쓰기 방지 로직 필요.

## 5. 결론 및 제언
본 Hyper-Atomized 구조는 초기 개발 공수는 증가하나, 실물 매매 환경에서 가장 빈번하게 발생하는 **"알 수 없는 지연"**에 대해 시스템이 명확한 인과관계를 가지고 대응할 수 있게 함. 

---
**Last Modified**: 2026-05-19
**Reporter**: Gemini-3.1-Flash-Lite (cli-agent)
