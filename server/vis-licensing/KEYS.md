# Chaves locais da EP25

A chave privada de licenciamento **não entra no Git**.

## Gerar chave Ed25519 no Windows
No diretório local do servidor:

```powershell
New-Item -ItemType Directory -Force .local-secrets | Out-Null
openssl genpkey -algorithm ED25519 -out .local-secrets/vis-license-ed25519.pem
$env:VIS_LICENSE_PRIVATE_KEY_FILE = (Resolve-Path .local-secrets/vis-license-ed25519.pem)
$env:VIS_LICENSE_KEY_ID = "vis-license-signing-1"
npm start
```

Se `openssl` não estiver disponível, gere uma chave Ed25519 por uma ferramenta criptográfica confiável instalada no ambiente. Não use geradores online.

O servidor falha ao iniciar se `VIS_LICENSE_PRIVATE_KEY_FILE` não estiver definido ou se a chave não for Ed25519.

## Chave pública
Com o servidor iniciado:

```powershell
Invoke-RestMethod http://127.0.0.1:8787/api/v1/licensing/public-key
```

Somente a chave pública será incorporada/configurada no APK para verificar credenciais.

## Produção
A chave de produção será diferente da chave de desenvolvimento e deverá ficar em secret store/KMS/HSM ou mecanismo equivalente, com backup e política de rotação. Nunca versionar a chave privada.
