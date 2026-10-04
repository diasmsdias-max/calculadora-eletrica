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
try {
    $caCertificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new($caBytes)
} catch {
    throw 'CaCertificatePath não contém um certificado X.509 válido.'
}
try {
    if ($caCertificate.HasPrivateKey) { throw 'CaCertificatePath contém uma chave privada; use somente o certificado público da CA.' }
    $basicConstraints = $caCertificate.Extensions |
        Where-Object { $_.Oid.Value -eq '2.5.29.19' } |
        Select-Object -First 1
    if (-not $basicConstraints -or -not $basicConstraints.CertificateAuthority) {
        throw 'CaCertificatePath não é um certificado de autoridade certificadora (CA).'
    }
    $pemBody = [Convert]::ToBase64String(
        $caCertificate.RawData,
        [Base64FormattingOptions]::InsertLineBreaks
    )
    $caPem = "-----BEGIN CERTIFICATE-----`r`n$pemBody`r`n-----END CERTIFICATE-----`r`n"
    $caBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($caPem))
} finally {
    $caCertificate.Dispose()
}

$defines = @(
    '--dart-define=EP25_VALIDATE_BUILD_CONFIGURATION=true',
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
    Write-Output 'Validando os dart-defines da EP25 no runtime Flutter...'
    & $FlutterExecutable test test/core/licensing/ep25_build_configuration_test.dart @defines
    if ($LASTEXITCODE -ne 0) {
        throw "A validação dos dart-defines da EP25 falhou com código $LASTEXITCODE. O APK não será declarado configurado."
    }

    $buildStartedUtc = [DateTime]::UtcNow
    & $FlutterExecutable build apk --debug @defines
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk falhou com código $LASTEXITCODE." }
} finally {
    Pop-Location
}

$apk = Join-Path $repositoryRoot 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path -LiteralPath $apk -PathType Leaf)) { throw "APK não encontrado após o build: $apk" }
$apkInfo = Get-Item -LiteralPath $apk
if ($apkInfo.Length -lt 1MB) { throw "O arquivo gerado é pequeno demais para ser um APK válido: $($apkInfo.Length) bytes." }
if ($apkInfo.LastWriteTimeUtc -lt $buildStartedUtc.AddSeconds(-2)) {
    throw "O APK encontrado não foi atualizado por este build (timestamp: $($apkInfo.LastWriteTimeUtc.ToString('o')))."
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($apk)
try {
    $entryNames = @($archive.Entries | ForEach-Object FullName)
    if ($entryNames -notcontains 'AndroidManifest.xml') { throw 'APK inválido: AndroidManifest.xml ausente.' }
    if (-not ($entryNames | Where-Object { $_ -match '^classes\d*\.dex$' })) { throw 'APK inválido: classes.dex ausente.' }
} finally {
    $archive.Dispose()
}

$apkHash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output 'Validação EP25 concluída: configuração aceita pelo runtime e APK íntegro/fresco.'
Write-Output "APK EP25 gerado: $apk"
Write-Output "SHA-256: $apkHash"
Write-Output "Tamanho: $($apkInfo.Length) bytes"

