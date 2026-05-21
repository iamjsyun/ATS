# XTX Atomized Task Strategy Report v1.0

## 1. 개요 (Overview)
트레이딩 시퀀스의 각 단계를 **1 Task 1 Responsibility (1T1R)** 원칙에 따라 세분화하여, 브로커 응답 지연 및 DB I/O 병목에 대한 방어적 안정성을 확보하기 위한 전략 보고서임.

## 2. 정량적 분석 (Quantitative Analysis)

| 항목 (Metric) | 현행 (Current) | 목표 (Target) | 변동률 (Delta) | 비고 |
| :--- | :---: | :---: | :---: | :--- |
| **Task 클래스 수** | 12개 | **28개** | +133% | 기능별 원자화 분리 |
| **상태 전이 단계** | 6단계 | **14단계** | +133% | 과도기 상태(Transit) 추가 |
| **평균 파일 라인 수** | ~80L | **~40L** | -50% | 단일 책임 집중 |
| **재시도 정밀도** | 1회/단계 | **3회/세부단계** | +200% | 미세 장애 복구력 향상 |
| **로직 테스트 가능성** | 낮음 | **매우 높음** | - | 순수 로직 Task 분리 효과 |

## 3. 책임 세분화 맵 (Task Atomization Map)

### 진입 시퀀스 (Entry Sequence)
1. `Task_Entry_L_Calc`: 로직 판단 및 진입가 계산
2. `Task_Entry_P_Lock`: DB `PENDING_REQ` 상태 잠금
3. `Task_Entry_R_Order`: 브로커 주문 송신 (Async)
4. `Task_Entry_V_Ticket`: 티켓 번호 유효성 및 응답 검증
5. `Task_Entry_P_Finalize`: DB `EXECUTED` 최종 확정

### 트레일링/감시 시퀀스 (Monitoring Sequence)
1. `Task_Sync_V_Terminal`: 터미널 실물 자산 상태 재조회
2. `Task_Sync_P_Align`: DB 상태와 실물 상태 동기화
3. `Task_Trail_L_Calc`: 가격 개선 로직 계산
4. `Task_Trail_R_Modify`: 브로커 주문 수정 요청

## 4. 작업 계획 (Action Plan)

### Phase 1: 인프라 고도화
- `XE_PENDING_REQ`, `XE_IN_TRANSIT`, `XE_VERIFY_ABS` 등 상태 코드 확장.
- `ICXTask` 내 재시도(Retry) 및 타임아웃(Timeout) 속성 표준화.

### Phase 2: 시퀀스 원자화 리팩토링
- 진입(`EntryTasks`), 대기(`PendingTasks`), 활성(`ActiveTasks`) 파일을 1T1R 기준으로 물리적 분할.
- `CXTradingSession` 내 시퀀스 조립 로직 업데이트.

### Phase 3: 방어 기제 검증
- 네트워크 지연(3s+) 상황 시뮬레이션을 통한 중복 주문 방지 검증.
- SQLite I/O 잠금 상황에서의 순차 처리 및 재시도 무결성 테스트.

---
**Last Modified**: 2026-05-19
**Reporter**: Gemini-3.1-Flash-Lite (cli-agent)
