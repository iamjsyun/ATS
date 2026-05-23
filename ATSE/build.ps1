param(
    [string]$File = "CXTrade\ATS.mq5"
)

# Ensure UTF-8 encoding for script output
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$MetaEditor = "D:\Program Files\XM Global MT5\MetaEditor64.exe"
$ProjectRoot = "D:\Projects\ATS"
$LogDir = "$ProjectRoot\_log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "build_$Timestamp.log"
$SourceFile = "$ProjectRoot\ATSE\$File"

Write-Host "--- ATSE MQL5 Build Started ---"
Write-Host "Source: $SourceFile"
Write-Host "Compiler: $MetaEditor"
Write-Host "Log: $LogFile"

if (-not (Test-Path $SourceFile)) {
    Write-Error "Error: Source file not found at $SourceFile"
    exit 1
}

# Execute compilation
$process = Start-Process -FilePath $MetaEditor -ArgumentList "/compile:`"$SourceFile`"", "/log:`"$LogFile`"" -Wait -NoNewWindow -PassThru
$RawExitCode = $process.ExitCode

# Short delay to ensure file system sync for the log file
Start-Sleep -Milliseconds 500

$BuildSuccess = $false
if (Test-Path $LogFile) {
    # MetaEditor log is typically UTF-16 LE (Unicode in PowerShell)
    $LogContent = Get-Content $LogFile -Encoding Unicode
    Write-Host "--- Build Log Output ---"
    $LogContent | ForEach-Object { 
        Write-Host $_ 
        if ($_ -match "0 errors") {
            $BuildSuccess = $true
        }
    }
} else {
    Write-Host "Warning: Build log file not found at $LogFile"
}

if ($BuildSuccess) {
    Write-Host "SUCCESS: Build completed successfully (0 errors)." -ForegroundColor Green
    exit 0
} else {
    Write-Host "FAILURE: Build failed or produced errors. Raw Exit Code: $RawExitCode" -ForegroundColor Red
    exit 1
}
