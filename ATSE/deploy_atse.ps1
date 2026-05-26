# [v1.0] ATSE Auto-Deploy Script for MetaTrader 5 Experts
$BuildOutput = Join-Path $PSScriptRoot "CXTrade\ATS.ex5"

if (-not (Test-Path $BuildOutput)) {
    Write-Host "ERROR: Compiled binary not found at: $BuildOutput" -ForegroundColor Red
    Write-Host "Please run build_atse.ps1 first to compile the EA." -ForegroundColor Yellow
    exit 1
}

# AppData 로밍 폴더 하위의 MetaQuotes 터미널 폴더 스캔
$TerminalBase = Join-Path $env:APPDATA "MetaQuotes\Terminal"
if (-not (Test-Path $TerminalBase)) {
    Write-Host "ERROR: MetaQuotes Terminal directory not found at $TerminalBase" -ForegroundColor Red
    exit 1
}

# 'MQL5\Experts' 디렉토리가 하위에 들어있는 실제 작동 중인 터미널 인스턴스 검색
$Targets = Get-ChildItem -Path $TerminalBase -Directory | Where-Object { Test-Path (Join-Path $_.FullName "MQL5\Experts") }

if ($Targets.Count -eq 0) {
    Write-Host "WARNING: No active MetaTrader 5 terminal directories with MQL5\Experts found." -ForegroundColor Yellow
    exit 0
}

Write-Host "--- ATSE Auto-Deploy Initiated ---" -ForegroundColor Cyan
Write-Host "Source: $BuildOutput"

$successCount = 0
foreach ($T in $Targets) {
    $DestDir = Join-Path $T.FullName "MQL5\Experts"
    $DestFile = Join-Path $DestDir "ATS.ex5"
    
    try {
        Copy-Item -Path $BuildOutput -Destination $DestFile -Force -ErrorAction Stop
        Write-Host "SUCCESS: Deployed to -> $DestFile" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "FAILED: Could not copy to $DestFile. Reason: $_" -ForegroundColor Red
    }
}

Write-Host "`nDeploy finished. Total deployed terminals: $successCount" -ForegroundColor Cyan
