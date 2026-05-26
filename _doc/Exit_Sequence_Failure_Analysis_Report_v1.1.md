# Exit Sequence Failure Analysis Report (v1.1)

## 1. 개요 (Executive Summary)
본 보고서는 1차 패치(Fast-Pass 보완 및 SID 공백 제거) 및 컴파일 빌드 성공 완료 후, 신규 신호 레코드(`ID: 13734`, `sno=2`)가 여전히 청산 의도(`xa_exit=1`) 상태에서 `xe_status`가 빈 상태(0 / NULL)로 정체되며 자산 청산 오류를 일으키는 2차 현상에 대한 정밀 원인 분석 및 배포(Deploy) 아키텍처적 개선안을 제시한다.

### 2차 분석 대상 데이터 (Case 2)
* **ID**: `13734`
* **SID**: `1001-26052618-02-00-1-1`
* **CNO / SNO**: `1001` / `2`
* **의도 필드**: `xa_entry=1`, `xa_exit=1`
* **상태 필드 (`xe_status`)**: 빈 값 (0 또는 NULL)

---

## 2. 2차 동작 실패 원인 분석 (Deploy Sync Disconnect)

1차 패치를 통해 코드 수준의 모든 갭(유령 신호 Fast-Pass ticket=0 방어 및 SID 공백 Trim)이 해소되고 컴파일 빌드도 경고 없이 통과했음에도 동일한 오류가 재발한 원인은 **로컬 빌드 아웃풋과 실제 MT5 터미널의 실행 런타임 간의 물리적 배포(Deploy) 누락**에 있다.

```
[로컬 소스 코드 수정] (CXMacros, CXStepValidation 등)
         │
         ▼
[로컬 컴파일 빌드 완료] ──► ATS.ex5 바이너리가 'D:\Projects\ATS\ATSE\CXTrade\' 에 생성됨.
         │
         ❌ (물리적 복사/배포 누락 - Disconnect)
         ▼
[MT5 터미널 런타임] ──► 여전히 'C:\Users\...\MQL5\Experts\' 에 위치한 "이전 버전"의 ATS.ex5 구동 중.
         │
         ▼
[결과] 패치가 적용되지 않은 구버전 엔진이 xa_exit=1을 감지하여 유령 신호 교착 상태 재발.
```

### 2.1. build_atse.ps1 한계점 분석
* `build_atse.ps1`은 MetaEditor를 호출하여 로컬 작업 경로(`D:\Projects\ATS\ATSE\CXTrade\ATS.mq5`) 기준으로 컴파일하여 로컬 디렉토리에 `ATS.ex5`를 빌드하는 작업만 담당한다.
* 실제 MT5 터미널이 구동되고 엑스퍼트 어드바이저(EA)를 차트에 로드하는 경로는 사용자 로밍 데이터 폴더(예: `C:\Users\hijsyun\AppData\Roaming\MetaQuotes\Terminal\{Terminal_Hash_ID}\MQL5\Experts\`)이다.
* 컴파일이 완료된 후 새 `.ex5` 바이너리를 해당 터미널 폴더로 복사해주는 배포 자동화 단계가 부재하여, 터미널에서는 패치 이전의 엔진이 동작하고 있어 정체 현상이 지속되고 있다.

---

## 3. 해결 및 자동 배포(Deploy) 시정 조치

컴파일 완료 시 자동으로 실시간 터미널 Experts 디렉토리를 찾아 빌드 아웃풋을 동기화시키는 배포 파이프라인을 구축한다.

### 3.1. 자동 배포 스크립트 설계 (`deploy_atse.ps1`)
터미널 데이터 폴더를 탐색하여 `ATS.ex5`를 자동으로 배포해주는 PowerShell 스크립트를 작성하여 가동한다.

```powershell
# D:\Projects\ATS\ATSE\deploy_atse.ps1 (예시 설계)
$BuildOutput = "D:\Projects\ATS\ATSE\CXTrade\ATS.ex5"
if (-not (Test-Path $BuildOutput)) {
    Write-Host "ERROR: Build output not found. Build first." -ForegroundColor Red
    exit 1
}

# 로밍 폴더 하위의 MetaQuotes 터미널 폴더 스캔
$TerminalBase = Join-Path $env:APPDATA "MetaQuotes\Terminal"
if (Test-Path $TerminalBase) {
    # 해시로 된 각 터미널 디렉토리 검색
    $Targets = Get-ChildItem -Path $TerminalBase -Directory | Where-Object { Test-Path (Join-Path $_.FullName "MQL5\Experts") }
    
    foreach ($T in $Targets) {
        $Dest = Join-Path $T.FullName "MQL5\Experts\ATS.ex5"
        Copy-Item -Path $BuildOutput -Destination $Dest -Force
        Write-Host "SUCCESS: Deployed to $Dest" -ForegroundColor Green
    }
} else {
    Write-Host "WARNING: MetaQuotes Terminal path not found." -ForegroundColor Yellow
}
```

### 3.2. 수동 복사 검증 가이드
자동 스크립트 도입 전, 아래 명령어를 실행하여 수동으로 빌드 결과물을 터미널 데이터 경로로 복사한 후 터미널 내 EA를 우클릭 ➔ '새로고침(Refresh)'하여 정상 동작 여부를 검증한다.

```powershell
# 수동 배포 명령어 예시 (사용자의 터미널 경로가 확정되었을 때 실행)
Copy-Item -Path "D:\Projects\ATS\ATSE\CXTrade\ATS.ex5" -Destination "$env:APPDATA\MetaQuotes\Terminal\{사용자_터미널_해시}\MQL5\Experts\ATS.ex5" -Force
```

---
**문서 버전**: v1.1 (PDCA/Design Storage Standard 준수 - 2차 실패 분석 통합)
**작성 주체**: Antigravity AI Coding System
**승인 상태**: 최초 작성 및 검토 대기
