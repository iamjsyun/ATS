# ATSA-ATSE State Transition Synchronization Analysis (v1.0)

## 1. 개요
본 문서는 ATSA(UI/Orchestrator)와 ATSE(MQL5 Engine) 간의 `xa_exit` 상태 전이 정합성 분석 결과를 기록합니다. 이 내용은 추후 일괄 동기화 작업 시 기초 자료로 사용됩니다.

## 2. xa_exit 상태 전이 매트릭스 (v9.8.11)
- **0 (RAW/READY)**: 진입 대기 및 실행 중.
- **1 (ACTIVE)**: 청산 요청(Exit Request) 송신 완료.
- **2 (COMP)**: 물리적 청산 완료 확인.
- **3 (ARCH)**: 히스토리 이관 대기 (Active 테이블 점유 해제).

## 3. 예외적 0 -> 2 직권 전이 시나리오
정상 흐름(0→1→2)을 벗어나 ATSA가 직권으로 `xa_exit`를 2로 변경해야 하는 상황들:
1. **MT5 수동 종료**: 사용자가 터미널에서 직접 포지션을 닫음 (`xe_status=24`).
2. **SL/TP 자동 청산**: 서버 측에서 가격 터치로 종료됨 (`xe_status=21/22`).
3. **엔진 에러/강제 종료**: 증거금 부족 또는 브로커 에러로 인한 종료 (`xe_status=99`).

## 4. 식별된 위반 및 개선 사항 (To-Be)
### 4.1 Audit Log 기록 미비
- **현상**: `0 -> 2` 점프 시 '청산 요청(1)' 로그가 없어 정상 청산과 구분이 어려움.
- **대응**: `XAuditFormatter`에 "Engine-Forced Completion" 또는 "External Exit Detected" 태그를 추가하여 기록 보강.

### 4.2 이관 지연 (Latency)
- **현상**: `2 -> 3` 전이가 다음 워커 루프(10초)에서 발생하여 지연됨.
- **대응**: `xa_exit=2` 확인 즉시 동일 트랜잭션 내에서 `3`으로 전이하는 Fast-Track 로직 검토.

### 4.3 UI 정합성 (SelectedXEStatus)
- **현상**: DB 상태값은 변경되나 UI 바인딩 문자열(`SelectedXEStatus`)이 즉시 갱신되지 않을 수 있음.
- **대응**: 상태 변경 커맨드 마지막에 `RefreshAll()` 호출 강제화.

## 5. 결론 및 향후 계획
현재 ATSA는 "있는 그대로 전달" 원칙에 따라 데이터를 유지하고 있으며, 위 분석 내용을 바탕으로 ATSE 엔진과의 일괄 동기화 시점에 `XSyncWorker` 및 `XpoSqliteService`의 전이 로직을 최적화할 예정입니다.

---
**Documented by Gemini CLI Orchestrator (2026-05-22)**
