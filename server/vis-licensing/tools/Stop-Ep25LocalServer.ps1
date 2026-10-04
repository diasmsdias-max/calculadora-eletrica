[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$serverRoot = Split-Path -Parent $PSScriptRoot
$dataRoot = Join-Path $serverRoot '.local-data'

foreach ($entry in @(
    @{ File = 'https-gateway.pid'; Pattern = 'https-gateway\.js' },
    @{ File = 'api.pid'; Pattern = 'vis-licensing.+server\.js' }
)) {
    $pidFile = Join-Path $dataRoot $entry.File
    if (-not (Test-Path -LiteralPath $pidFile)) { continue }
    $processId = [int](Get-Content -LiteralPath $pidFile -Raw)
    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $processId" -ErrorAction SilentlyContinue
    if ($process -and $process.CommandLine -notmatch $entry.Pattern) {
        throw "PID $processId não corresponde ao processo EP25 esperado; encerramento recusado."
    }
    if ($process) { Stop-Process -Id $processId -ErrorAction Stop }
    Remove-Item -LiteralPath $pidFile -ErrorAction SilentlyContinue
}

Write-Output 'Servidor local EP25 encerrado.'

