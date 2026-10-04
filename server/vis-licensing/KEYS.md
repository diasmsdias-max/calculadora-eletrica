# Chaves locais da EP25

A chave privada de licenciamento **não entra no Git**.

## Gerar chave Ed25519 no Windows
No diretório raiz do repositório, usando somente o Node.js 20+:

```powershell
node .\server\vis-licensing\tools\generate-dev-signing-key.js
```

O script recusa substituir uma chave existente. `--force` existe apenas para uma rotação deliberada, que invalida a chave pública configurada nos APKs anteriores.

O servidor falha ao iniciar se `VIS_LICENSE_PRIVATE_KEY_FILE` não estiver definido ou se a chave não for Ed25519.

## Chave pública
Com o servidor iniciado pelo procedimento físico:

```powershell
Invoke-RestMethod http://127.0.0.1:8787/api/v1/licensing/public-key
```

Somente a chave pública será incorporada/configurada no APK para verificar credenciais.

## Produção
A chave de produção será diferente da chave de desenvolvimento e deverá ficar em secret store/KMS/HSM ou mecanismo equivalente, com backup e política de rotação. Nunca versionar a chave privada.
