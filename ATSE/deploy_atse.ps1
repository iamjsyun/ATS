# [v1.0] ATSE Auto-Deploy Script for MetaTrader 5 Experts 
$BuildOutput = Join-Path $PSScriptRoot "CXTrade\ATS.ex5" 
 
if (-not (Test-Path $BuildOutput)) { 
    Write-Host "ERROR: Compiled binary not found at: $BuildOutput" -ForegroundColor Red 
    exit 1 
} 
 
$TerminalBase = Join-Path $env:APPDATA "MetaQuotes\Terminal" 
if (-not (Test-Path $TerminalBase)) { 
    Write-Host "ERROR: MetaQuotes Terminal directory not found at $TerminalBase" -ForegroundColor Red 
    exit 1 
} 
 
$Targets = Get-ChildItem -Path $TerminalBase -Directory | Where-Object { Test-Path (Join-Path $_.FullName "MQL5\Experts") } 
 
if (-not $Targets -or $Targets.Count -eq 0) { 
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
