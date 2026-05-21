## Gemini Added Memories
- PDCA 문서(Plan, Design, Analysis, Report)는 항상 한국어로 작성한다.
- 바이너리(예: .ex5) 생성 및 빌드 작업은 사용자의 명시적인 요청이 있을 때만 수행한다.
- 기본 언어는 한국어이며, 모든 문서는 UTF-8로 저장한다.
- MT5 컴파일러 경로는 'D:\Program Files\XM Global MT5\MetaEditor64.exe'이다.
- 모든 응답, 셸 명령 출력 및 문자열 생성 시 한국어를 사용하며, 파일 저장 및 출력 인코딩은 반드시 UTF-8을 준수한다.
- Git 실행 파일 경로는 'D:\Program Files\Git\cmd\git.exe'이다. 모든 git 명령어는 이 전체 경로를 사용하여 실행해야 한다.
- Git executable path is 'D:\Program Files\Git\cmd\git.exe'. Use this full path for all git commands on this system.
- ILogger 사용 시 반드시 NLog.ILogger와 같이 네임스페이스를 명시적으로 표기한다. (Microsoft.Extensions.Logging.ILogger 등과의 혼동 방지)
- 명령어 입력을 위해 '/'를 입력할 때 자동으로 영문 모드로 전환되는 기능을 선호함.
- 셸 출력 인코딩 강제: 셸 명령(run_shell_command) 실행 시 출력 결과의 한글 깨짐을 방지하기 위해, 반드시 명령 앞에 $OutputEncoding = [System.Text.Encoding]::UTF8; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8;를 선행하여 실행하거나, 시스템 코드페이지를 65001로 유지하여 모든 출력이 UTF-8로 전달되도록 보장한다.
- **Caveman 모드 상시 가동**: Gemini CLI 기동 시 반드시 `caveman` (full intensity) 모드를 자동으로 활성화하여 토큰 사용량을 최적화한다.

## Simulator & Testing Mandate (v1.0)
- **Deterministic Testing**: 모든 ATSE 단위 테스트는 `VirtualClock` 기반의 결정성 시뮬레이션 환경에서 수행되어야 한다.
- **MT5 Independence**: 테스트 코드는 MT5 터미널 API에 직접 의존하지 않으며, 반드시 SSOC Mock 서비스(Price, Inventory, Symbol)를 통해야 한다.
- **Sequential Execution**: 로직 무결성 검증을 우선하며, 시뮬레이터 루프는 순차적(Sequential) 처리를 기본으로 한다.
- **CSV-Driven Scenarios**: 모든 테스트 케이스는 `_doc/test_scenarios/` 내 CSV 파일을 통해 관리 및 주입되어야 한다.
