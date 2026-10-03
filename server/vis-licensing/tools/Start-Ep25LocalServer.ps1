[CmdletBinding()]
param(
    [int]$ApiPort = 8787,
    [int]$HttpsPort = 8444,
    [string]$KeyId = 'vis-license-signing-1',
    [string]$SigningKeyPath = '',
    [string]$TlsCertificatePath = '',
    [string]$TlsPrivateKeyPath = ''
)

$ErrorActionPreference = 'Stop'
$serverRoot = Split-Path -Parent $PSScriptRoot
$repositoryRoot = (Resolve-Path (Join-Path $serverRoot '..\..')).Path
$dataRoot = Join-Path $serverRoot '.local-data'

if (-not $SigningKeyPath) { $SigningKeyPath = Join-Path $serverRoot '.local-secrets\vis-license-ed25519.pem' }
if (-not $TlsCertificatePath) { $TlsCertificatePath = Join-Path $repositoryRoot '..\certs\server.crt.pem' }
if (-not $TlsPrivateKeyPath) { $TlsPrivateKeyPath = Join-Path $repositoryRoot '..\certs\server.key.pem' }

$SigningKeyPath = (Resolve-Path -LiteralPath $SigningKeyPath).Path
$TlsCertificatePath = (Resolve-Path -LiteralPath $TlsCertificatePath).Path
$TlsPrivateKeyPath = (Resolve-Path -LiteralPath $TlsPrivateKeyPath).Path
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null

foreach ($port in @($ApiPort, $HttpsPort)) {
    if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
        throw "A porta $port já está em uso."
    }
}

$nodeExe = (Get-Command node -ErrorAction Stop).Source
$apiScript = Join-Path $serverRoot 'src\server.js'
$gatewayScript = Join-Path $serverRoot 'src\https-gateway.js'
$apiPidFile = Join-Path $dataRoot 'api.pid'
$gatewayPidFile = Join-Path $dataRoot 'https-gateway.pid'

$env:VIS_LICENSE_HOST = '127.0.0.1'
$env:VIS_LICENSE_PORT = $ApiPort.ToString()
$env:VIS_LICENSE_PRIVATE_KEY_FILE = $SigningKeyPath
$env:VIS_LICENSE_KEY_ID = $KeyId
$env:VIS_LICENSE_DATA_FILE = Join-Path $dataRoot 'licensing-v1.json'

$api = Start-Process -FilePath $nodeExe -ArgumentList ('"{0}"' -f $apiScript) -WorkingDirectory $serverRoot -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $dataRoot 'api.stdout.log') -RedirectStandardError (Join-Path $dataRoot 'api.stderr.log')
Set-Content -LiteralPath $apiPidFile -Value $api.Id -NoNewline
Start-Sleep -Milliseconds 750
if ($api.HasExited) {
    $details = Get-Content -LiteralPath (Join-Path $dataRoot 'api.stderr.log') -Raw -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $apiPidFile -ErrorAction SilentlyContinue
    throw "A API de licenciamento falhou ao iniciar. $details"
}

$env:VIS_LICENSE_HTTPS_HOST = '0.0.0.0'
$env:VIS_LICENSE_HTTPS_PORT = $HttpsPort.ToString()
$env:VIS_LICENSE_TLS_CERT_FILE = $TlsCertificatePath
$env:VIS_LICENSE_TLS_KEY_FILE = $TlsPrivateKeyPath
$gateway = Start-Process -FilePath $nodeExe -ArgumentList ('"{0}"' -f $gatewayScript) -WorkingDirectory $serverRoot -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $dataRoot 'https.stdout.log') -RedirectStandardError (Join-Path $dataRoot 'https.stderr.log')
Set-Content -LiteralPath $gatewayPidFile -Value $gateway.Id -NoNewline
Start-Sleep -Milliseconds 750
if ($gateway.HasExited) {
    Stop-Process -Id $api.Id -ErrorAction SilentlyContinue
    $details = Get-Content -LiteralPath (Join-Path $dataRoot 'https.stderr.log') -Raw -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $apiPidFile,$gatewayPidFile -ErrorAction SilentlyContinue
    throw "O gateway HTTPS falhou ao iniciar. $details"
}

Write-Output "API local: http://127.0.0.1:$ApiPort/ (PID $($api.Id))"
Write-Output "Painel BOECKER: http://127.0.0.1:$ApiPort/admin-ui/"
Write-Output "API HTTPS LAN: https://0.0.0.0:$HttpsPort/api/v1/licensing/ (PID $($gateway.Id))"

