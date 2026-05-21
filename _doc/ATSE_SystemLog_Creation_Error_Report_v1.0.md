# ATSE 시스템 로그 파일 생성 오류 분석 보고서 (v1.0)
**날짜**: 2026-05-19
**작성자**: Gemini CLI
**상태**: 완료 (Fix Applied)

## 1. 현상 개요 (Plan)
ATS.mq5 EA 구동 시, 시스템 초기화 및 전역 상태를 기록해야 하는 시스템 로그 파일(System Log)이 지정된 경로에 생성되지 않는 현상이 지속적으로 발생함.
- 목표 파일명 규격: ATSE_{yyMMdd-HH0000}.log
- 목표 저장 경로: MQL5 Terminal/Common/Files

## 2. 원인 분석 및 진단 (Do)
CXFileLogger.mqh 내부의 파일 오픈 로직(OpenByTime)을 분석한 결과, 시스템 로그 파일이 생성되지 못한 이유는 다음과 같음.

### 2.1 잘못된 MQL5 디렉토리 제어 함수 사용
- 오류 내역: MQL5 내장 함수에 존재하지 않는 FolderIsExist 및 FolderCreate 함수를 호출하도록 코드가 작성되어 있었음.
- 파급 효과: 해당 함수들은 컴파일 에러를 유발하였으며, 컴파일을 억지로 통과시키거나 예외 처리로 무시하더라도 실제 디렉토리(ATSE\)를 생성하지 못함.

### 2.2 MQL5 Sandbox 및 FileOpen 동작 한계
- 오류 내역: MQL5의 FileOpen 함수는 지정된 파일명에 하위 경로(예: "ATSE\ATSE_260519-070000.log")가 포함되어 있을 때, 해당 하위 디렉토리가 미리 존재하지 않으면 파일을 강제로 생성하지 못하고 에러(INVALID_HANDLE, Error 5002/5004)를 반환함.
- 파급 효과: 사용자가 수동으로 Common/Files/ATSE 폴더를 만들어두지 않는 한, 시스템 로거는 초기화에 실패하고 이후 발생하는 모든 부팅/시스템 로그가 무음(Silent) 처리됨.

## 3. 조치 사항 (Check)
문제 해결을 위해 CXFileLogger.mqh 모듈을 다음과 같이 수정함.

### 3.1 로그 파일 저장 경로 평탄화 (Flattening)
- 조치: 존재하지 않는 하위 폴더(ATSE\) 의존성을 제거함.
- 내용: 파일명을 "ATSE\\ATSE_%s.log"에서 "ATSE_%s.log"로 수정하여, 폴더 생성 없이 Common/Files/ 루트 경로에 직접 파일이 생성되도록 구조를 단순화함.

### 3.2 파일 명명 규칙(Naming Convention) 분기 처리
- 조치: 시스템 로그와 개별 신호 로그의 식별을 명확히 함.
- 내용: 
  - m_sid == "System" 인 경우: ATSE_{yyMMdd-HH0000}.log 로 생성.
  - 개별 신호(Signal) 인 경우: {sid}-{yyMMdd-HH0000}.log 로 생성.

### 3.3 에러 추적 로직(Diagnostic Logging) 강화
- 조치: FileOpen 실패 시 명확한 사유를 알 수 있도록 터미널 Experts 탭에 에러를 출력.
- 내용: m_handle == INVALID_HANDLE 일 경우 _LastError 값을 포함하여 PrintFormat 출력.

## 4. 결과 및 향후 대응 (Act)
- 결과 확인: 코드를 재컴파일 후 EA를 실행하면, 별도의 사전 작업(폴더 수동 생성 등) 없이 즉시 Common/Files 폴더 내에 ATSE_260519-XX0000.log 파일이 자동 생성됨.
- 향후 대응: MQL5 환경에서의 파일 I/O 작업 시, Sandbox 제한 사항을 고려하여 하위 디렉토리 사용을 지양하고 Prefix 방식의 파일명 평탄화 패턴을 기본 규칙으로 유지함.
