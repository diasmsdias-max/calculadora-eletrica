[CmdletBinding()]
param([int]$HttpsPort = 8444)

$ErrorActionPreference = 'Stop'
$name = "VIS ELECTRICA EP25 HTTPS TCP $HttpsPort"
if (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue) {
    Write-Output "A regra já existe: $name"
    exit 0
}

New-NetFirewallRule `
    -DisplayName $name `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort $HttpsPort `
    -Profile Private,Public `
    -RemoteAddress LocalSubnet | Out-Null
Write-Output "Regra criada: $name (TCP $HttpsPort, somente LocalSubnet)"

