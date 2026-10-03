# EP25 — Contrato de API de Licenciamento VIS (v1)

Este contrato detalha a primeira implementação do fluxo definido em `EP25_LICENSING_AND_MANAGEMENT.md`.

## Convenções
- Base: `/api/v1/licensing`
- Produção: HTTPS obrigatório.
- JSON UTF-8.
- Datas: ISO-8601 UTC.
- `contractVersion`: `1`.
- Chaves de ativação são tratadas como segredo de entrada e nunca aparecem em logs.
- Respostas de erro públicas não revelam se uma licença pertence a outro cliente nem identificadores de outras instalações.

## POST /activate
Ativa ou recupera idempotentemente a autorização da instalação.

Request:
```json
{
  "contractVersion": 1,
  "activationKey": "VIS-PRO-XXXX-XXXX-XXXX",
  "installationId": "random-installation-id",
  "app": {
    "version": "1.0.0",
    "build": "1",
    "platform": "android"
  }
}
```

Regras:
1. Validar formato e chave.
2. Validar status e validade comercial.
3. Se `installationId` já estiver ACTIVE nessa licença, não consumir nova vaga.
4. Caso contrário, contar instalações ACTIVE.
5. Se `activeDevices >= maxDevices`, responder `DEVICE_LIMIT_REACHED`.
6. Registrar ativação e auditoria.
7. Emitir credencial assinada vinculada à licença e ao `installationId`.

Sucesso:
```json
{
  "contractVersion": 1,
  "status": "ACTIVE",
  "license": {
    "licenseId": "lic_...",
    "plan": "professional",
    "permissions": ["professional"],
    "commercialValidUntil": "2027-10-02T23:59:59Z",
    "maxDevices": 1,
    "activeDevices": 1
  },
  "credential": {
    "format": "VIS-LIC-1",
    "payload": "<base64url>",
    "signature": "<base64url>",
    "keyId": "vis-license-signing-1"
  },
  "serverTime": "2026-10-03T00:00:00Z"
}
```

## POST /refresh
Renova a janela offline de uma instalação já ativa.

Request identifica a instalação e apresenta a credencial vigente. O servidor deve validar assinatura, vínculo, status da licença e status da instalação antes de emitir nova credencial.

Uma instalação DEACTIVATED/REVOKED não recebe renovação.

## POST /validate
Validação online explícita. Retorna o estado atual da licença/instalação sem criar uma nova instalação. Pode emitir credencial atualizada quando a política do servidor permitir.

## POST /deactivate
Desativa a instalação autenticada conforme política definida. A primeira versão administrativa pode executar a transferência pelo painel; autoatendimento do cliente não é requisito inicial.

## Payload assinado da credencial
Antes da assinatura, o payload canônico contém no mínimo:

```json
{
  "contractVersion": 1,
  "credentialFormat": "VIS-LIC-1",
  "licenseId": "lic_...",
  "installationId": "...",
  "plan": "professional",
  "permissions": ["professional"],
  "issuedAt": "2026-10-03T00:00:00Z",
  "offlineValidUntil": "2026-10-10T00:00:00Z",
  "commercialValidUntil": "2027-10-02T23:59:59Z",
  "keyId": "vis-license-signing-1"
}
```

A serialização usada para assinar deve ser determinística. O cliente nunca deve reconstruir uma decisão comercial a partir de campos não assinados.

## Erros públicos
Formato:
```json
{
  "contractVersion": 1,
  "error": {
    "code": "DEVICE_LIMIT_REACHED",
    "message": "Limite de dispositivos atingido."
  }
}
```

Códigos iniciais:
- `INVALID_REQUEST`
- `INVALID_ACTIVATION_KEY`
- `LICENSE_INACTIVE`
- `LICENSE_EXPIRED`
- `DEVICE_LIMIT_REACHED`
- `INSTALLATION_INACTIVE`
- `CREDENTIAL_INVALID`
- `RATE_LIMITED`
- `SERVER_ERROR`

## Idempotência e concorrência
Duas ativações simultâneas não podem ultrapassar `maxDevices`. A verificação do limite e a criação da instalação devem ocorrer dentro de transação/controle de concorrência no servidor.

Repetir `/activate` com a mesma licença + `installationId` deve devolver o estado ativo sem criar outra instalação.

## Janela offline
Valor inicial: 7 dias. O servidor define `offlineValidUntil`; o APK não pode estender esse prazo.

Ao ficar offline, o app valida localmente:
1. assinatura;
2. `installationId` correspondente à instalação local;
3. formato/versão suportados;
4. `offlineValidUntil`;
5. validade comercial presente na credencial;
6. permissão necessária.

## Configuração comercial
A configuração pública do VIS poderá fornecer canal comercial atual, por exemplo:
```json
{
  "contractVersion": 1,
  "commercialContact": {
    "channel": "whatsapp",
    "phoneE164": "+55...",
    "message": "Olá, gostaria de informações sobre o VIS ELECTRICA Profissional."
  }
}
```

O APK mantém fallback local. O cliente valida tipo e formato antes de abrir aplicativo externo.

## Requisitos para teste local
O servidor local deve permitir criar:
- 1 cliente de teste;
- 1 plano Profissional;
- 1 licença com limite de 1 aparelho;
- 1 chave de ativação;
- credencial offline de 7 dias.

O teste de dois aparelhos deve comprovar a recusa do segundo até a desativação do primeiro.
