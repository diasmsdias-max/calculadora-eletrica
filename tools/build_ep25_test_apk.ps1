[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LicenseApiBaseUrl,
    [Parameter(Mandatory)][string]$KeyId,
    [Parameter(Mandatory)][string]$PublicKeyBase64,
    [Parameter(Mandatory)][string]$CaCertificatePath,
    [string]$TechnicalCenterBaseUrl = '',
    [string]$FlutterExecutable = 'flutter'
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot

$apiUri = [uri]$LicenseApiBaseUrl
if ($apiUri.Scheme -ne 'https' -or $apiUri.UserInfo -or $apiUri.Query -or $apiUri.Fragment) {
    throw 'LicenseApiBaseUrl deve ser uma URL HTTPS sem credenciais, query ou fragmento.'
}
if ($apiUri.AbsolutePath.TrimEnd('/') -ne '/api/v1/licensing') {
    throw 'LicenseApiBaseUrl deve terminar em /api/v1/licensing/.'
}
if ([string]::IsNullOrWhiteSpace($KeyId)) { throw 'KeyId é obrigatório.' }
try { $publicKey = [Convert]::FromBase64String($PublicKeyBase64) } catch { throw 'PublicKeyBase64 não é Base64 válido.' }
if ($publicKey.Length -ne 32) { throw 'PublicKeyBase64 deve conter exatamente 32 bytes Ed25519.' }

$caPath = (Resolve-Path -LiteralPath $CaCertificatePath).Path
$caBytes = [IO.File]::ReadAllBytes($caPath)
$caText = [Text.Encoding]::ASCII.GetString($caBytes)
if ($caText -match 'PRIVATE KEY') { throw 'CaCertificatePath aponta para uma chave privada; use somente o certificado público da CA.' }
$caBase64 = [Convert]::ToBase64String($caBytes)

$defines = @(
    "--dart-define=VIS_LICENSE_API_BASE_URL=$LicenseApiBaseUrl",
    "--dart-define=VIS_LICENSE_KEY_ID=$KeyId",
    "--dart-define=VIS_LICENSE_PUBLIC_KEY_BASE64=$PublicKeyBase64",
    "--dart-define=VIS_LICENSE_CA_CERT_BASE64=$caBase64"
)
if ($TechnicalCenterBaseUrl) {
    $technicalUri = [uri]$TechnicalCenterBaseUrl
    if ($technicalUri.Scheme -ne 'https') { throw 'TechnicalCenterBaseUrl deve usar HTTPS.' }
    $defines += "--dart-define=VIS_TECHNICAL_CENTER_BASE_URL=$TechnicalCenterBaseUrl"
}

Push-Location $repositoryRoot
try {
    & $FlutterExecutable build apk --debug @defines
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk falhou com código $LASTEXITCODE." }
} finally {
    Pop-Location
}

$apk = Join-Path $repositoryRoot 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw "APK não encontrado após o build: $apk" }
Write-Output "APK EP25 gerado: $apk"

