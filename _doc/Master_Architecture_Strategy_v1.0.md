# ATS Master Architecture & Strategy Guide (v1.0)

## 1. 개요 (Overview)
본 문서는 ATS 시스템의 복잡도를 제어하고, 안정적인 트레이딩 환경을 구축하기 위한 아키텍처 원칙, 개발 전략 및 프로세스 흐름을 정의하는 통합 가이드이다.

---

## 2. 하이퍼-원자적 아키텍처 (Hyper-Atomized Architecture)

### 2.1 핵심 설계 철학
- **1 Task = 1 Responsibility (1T1R)**: 모든 비즈니스 로직은 단일 책임을 가진 원자적 태스크로 분해한다.
- **의도 기반 실행 (Intent-Based Execution)**: 실행(Execution)과 확정(Commit)을 물리적으로 분리한다.
- **서비스 전권 위임 (SSOC)**: 가격 계산, 리스크 검증, 인벤토리 조회 등은 반드시 전용 매니저 서비스(SSOC)를 통해서만 수행한다.

### 2.2 L-P-R-V-P 레이어링 표준
모든 트랜잭션 시퀀스는 다음 5단계를 엄격히 준수한다.
1. **L (Logic)**: 메모리 내 데이터 및 SSOC 서비스를 이용한 순수 판단 (I/O 없음).
2. **P (Persistence)**: 실행 전 DB에 "의도" 기록 및 Race Condition 방지 잠금.
3. **R (Request)**: 브로커/터미널에 대한 물리적 명령 송신 (Async 지향).
4. **V (Verify)**: 명령 후 터미널 상태 재조회를 통한 결과 검증 (Post-Action Verification).
5. **P (Persistence)**: 검증 완료된 결과의 최종 DB 상태 확정.

---

## 3. 내부 프로세스 흐름 (Internal Process Flow)

### 3.1 ATSE 상세 실행 트리
- **Discovery**: `SignalWatcher`가 DB에서 `xa_entry=1` 신호 포착 ➔ 세션 할당.
- **Entry Pipeline**: `Validate(L)` ➔ `Lock(P)` ➔ `Order(R)` ➔ `Ticket(V)` ➔ `Finalize(P)`.
- **Active Pipeline**: 실시간 `Terminal Sync(V)` ➔ `AlphaCalc(L)` ➔ `Modify(R)`.
- **Exit Pipeline**: `Prepare(L)` ➔ `Lock(P)` ➔ `Order(R)` ➔ `Terminal Absence Verify(V)` ➔ `Finalize(P)`.

### 3.2 Non-blocking Fault Tolerance
- `TASK_YIELD` 메커니즘을 통해 I/O 지연 시 전체 시스템 루프를 멈추지 않고 다음 틱에서 해당 단계부터 재시도한다.

---

## 4. 초정밀 Partial Class 구조 (Micro-Granular Strategy)

### 4.1 AI 컨텍스트 최적화
AI가 필요한 코드 문맥(100~300라인)만 로드하여 비용과 오류를 줄일 수 있도록 클래스를 물리적으로 분리한다.

### 4.2 파일 접미사(Suffix) 표준
| 접미사 | 포함 내용 |
| :--- | :--- |
| `.cs` | 클래스 선언, DI, 멤버 변수 (Core) |
| `.Models.cs` | 내부 전용 모델 (DTO, Enum) |
| `.Seq.cs` | FluentSeq 파이프라인 흐름 정의 |
| `.State.[Name].cs` | 특정 상태(State)의 독립적 구현 로직 |
| `.Validations.cs` | 정책 검증 및 가드(Guard) 로직 |
| `.Db.cs` | DB 쿼리 및 영속성 처리 |
| `.Events.cs` | 콜백, 로그, 외부 시스템 통지 |

---

## 5. 작업 추진 단계 (Action Plan)
1. **Phase 1: 인프라 고도화**: 과도기 상태 코드 및 재시도 표준화.
2. **Phase 2: 원자화 리팩토링**: 핵심 서비스를 초정밀 분리 규칙에 따라 물리적 분할.
3. **Phase 3: 무결성 검증**: 네트워크 지연 및 DB Lock 상황 시뮬레이션 테스트.

---
**Last Updated**: 2026-05-21
**Governance**: Single Source of "How-to-Build" for ATS Projects.
