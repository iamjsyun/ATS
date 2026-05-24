param(
    [string]$File = "CXTrade\ATS.mq5"
)

# [v12.1] Unified ATSE Portable Build Script (Relocated to ATSE folder)
# 1. UTF-8 Encoding for Console Output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 2. Path Configuration (Relative to Script Location: ATSE folder)
$AtseDir = $PSScriptRoot
$ProjectRoot = Split-Path -Parent $AtseDir
$MetaEditor = "D:\Program Files\XM Global MT5\MetaEditor64.exe"
$LogDir = Join-Path $ProjectRoot "_log"

# 3. Local Include Priority
# MetaEditor appends 'Include' to the /inc path automatically.
# Since this script is now INSIDE ATSE, we point to itself.
$StdInclude = $AtseDir

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "build_atse_$Timestamp.log"
$SourceFile = Join-Path $AtseDir $File

Write-Host "--- ATSE Portable Build Initiated ---" -ForegroundColor Cyan
Write-Host "Target: $SourceFile"
Write-Host "Include: $StdInclude (Local)"
Write-Host "Log: $LogFile"

if (-not (Test-Path $SourceFile)) {
    Write-Host "ERROR: Source file not found: $SourceFile" -ForegroundColor Red
    exit 1
}

# 4. Execute Compilation
$process = Start-Process -FilePath $MetaEditor -ArgumentList "/compile:`"$SourceFile`"", "/inc:`"$StdInclude`"", "/log:`"$LogFile`"" -Wait -NoNewWindow -PassThru

# 5. Result Analysis
if (Test-Path $LogFile) {
    Write-Host "`n--- Compiler Output ---"
    # Read as Unicode (UTF-16 LE) which is MetaEditor's default
    $logContent = Get-Content $LogFile -Encoding Unicode
    $logContent
    
    if ($logContent -like "*0 errors, 0 warnings*") {
        Write-Host "`nBUILD SUCCESS: 0 Errors, 0 Warnings." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`nBUILD FAILED: Errors detected. Check the log above." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ERROR: Build log not generated. Compiler may have failed to start." -ForegroundColor Red
    exit 1
}
