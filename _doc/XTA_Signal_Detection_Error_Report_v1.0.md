# XTA 신호 감지 오류 분석 보고서 (v1.0)
**날짜**: 2026-05-19
**작성자**: Gemini CLI
**상태**: 완료 (Fix Applied)

## 1. 개요 (Plan)
WPF 앱(ATSA)에서 DB로 신호가 정상적으로 주입되었으나, MQL5 EA(ATSE)의 Signal Watcher가 이를 감지하지 못하는 현상이 발생함 (대상 SID: 1001-26051910-01-00-1-1). 이에 대한 원인 분석 및 해결 방안을 수립함.

## 2. 분석 및 진단 (Do)
코드 및 로그 정밀 분석 결과, 세 가지 치명적인 결함이 발견됨.

### 2.1 시퀀스 시작 상태 오류 (Startup Bug)
- **현상**: SignalWatcher 로그에 Sequence Started at State: -1 기록됨.
- **원인**: CXFluentSequence::Build() 로직이 m_tmp_from 변수를 참조할 때, 이미 CommitCurrent()에 의해 -1로 초기화된 상태였음. 이로 인해 시퀀스가 WATCHER_DISCOVERY (0) 상태로 진입하지 못하고 미동작함.

### 2.2 DB 폴링 캐싱 오류 (Stale Query Bug)
- **현상**: DB에 신규 레코드가 추가되어도 ATSE가 인지하지 못함.
- **원인**: CXSignalRepository::LoadActiveSignals()에서 DatabasePrepare 핸들을 캐싱하고 DatabaseReset만 호출함. SQLite 명세상 DatabaseReset은 커서만 초기화할 뿐 쿼리를 재실행하지 않으므로, 준비 시점 이후의 신규 데이터는 무시됨.

### 2.3 로깅 가시성 누락 (Silent Log Bug)
- **현상**: 신호 감지 프로세스 중 발생하는 경고나 에러가 로그 파일에 남지 않음.
- **원인**: Watcher Step들에서 로깅 매크로 호출 시 xp 파라미터를 NULL로 전달하여 필터링 단계에서 로그가 차단됨.

## 3. 조치 사항 (Check)
발견된 모든 결함에 대해 즉각적인 수정 및 검증을 완료함.

| 대상 파일 | 수정 내용 | 결과 |
| :--- | :--- | :--- |
| CXFluentSequence.mqh | m_first_state 도입하여 시퀀스 시작점 보존 | 정상 기동 확인 |
| CXSignalRepository.mqh | 폴링 시 매번 DatabasePrepare 수행 (Polling Integrity) | 신규 데이터 감지 확인 |
| CXStepDiscovery.mqh 외 | 로깅 매크로에 xp 파라미터 연동 | 상세 로그 출력 확인 |
| CXFileLogger.mqh | 시간 단위 로그 로테이션 구현 (YYMMDD-HH) | 로그 관리 효율화 |

## 4. 향후 대응 (Act)
- 모니터링: 수정된 로직이 실제 거래 환경에서 안정적으로 동작하는지 지속 모니터링 수행.
- 표준화: 향후 시퀀스 기반 모듈 개발 시 CXFluentSequence의 초기화 표준 가이드 준수.
- 환경 공유: G:\공용 문서 폴더를 통한 지속적인 기술 리포트 공유 체계 확립.
