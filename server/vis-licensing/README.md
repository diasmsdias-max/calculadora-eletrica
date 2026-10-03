# VIS Licensing Server — EP25 local

Servidor executável de desenvolvimento da EP25. Usa Node.js 20+ sem dependências externas e persistência JSON local. **Não é o servidor de produção**; PostgreSQL continua sendo o destino previsto.

## Pré-requisitos

A assinatura Ed25519 é obrigatória. Gere e configure a chave conforme `KEYS.md`.

Por padrão o processo escuta somente `127.0.0.1:8787`. Para desenvolvimento no próprio PC, o painel BOECKER pode ser aberto em:

`http://127.0.0.1:8787/admin-ui/`

A API pública do Android deve ser publicada por HTTPS/reverse proxy. Não configure o APK para o HTTP interno.

## Executar

```powershell
cd server/vis-licensing
$env:VIS_LICENSE_PRIVATE_KEY_FILE = (Resolve-Path .local-secrets/vis-license-ed25519.pem)
$env:VIS_LICENSE_KEY_ID = "vis-license-signing-1"
npm start
```

Health:

```powershell
Invoke-RestMethod http://127.0.0.1:8787/health
```

A chave pública correspondente pode ser consultada em `/api/v1/licensing/public-key`. O campo `publicKeyRawBase64` tem os 32 bytes Ed25519 no formato esperado pelo build do APK. Essa rota é informativa: o aplicativo usa a chave pública fixada no build e não deve passar a confiar dinamicamente nela.

## Painel BOECKER e exposição de rede

O painel administrativo gerencia clientes, licenças e dispositivos. Em loopback ele permanece disponível para desenvolvimento local.

Se `VIS_LICENSE_HOST` for alterado para um endereço que exponha diretamente este processo fora do loopback, `VIS_LICENSE_ADMIN_TOKEN` passa a ser obrigatório e as rotas `/admin/*` e `/admin-ui/*` exigem o cabeçalho `X-VIS-Admin-Token`.

Para o teste com Android, a configuração preferida é manter o Node em loopback e publicar **somente** `/api/v1/licensing/` por meio do servidor HTTPS/reverse proxy já usado pelo VIS. O painel administrativo deve continuar local. Não exponha `/admin/*` nem `/admin-ui/*` no proxy.

## Teste rápido do licenciamento

Criar cliente:

```powershell
$customer = Invoke-RestMethod -Method Post -ContentType 'application/json' -Uri http://127.0.0.1:8787/admin/customers -Body '{"name":"Cliente Teste","companyName":"VIS Teste"}'
```

Criar licença:

```powershell
$body = @{ customerId = $customer.customer.id; planCode = 'professional'; maxDevices = 1 } | ConvertTo-Json
$license = Invoke-RestMethod -Method Post -ContentType 'application/json' -Uri http://127.0.0.1:8787/admin/licenses -Body $body
$license
```

A chave completa é mostrada somente na criação. O armazenamento persiste apenas SHA-256 + dica final.

Ativar instalação A:

```powershell
$activate = @{
  contractVersion = 1
  activationKey = $license.activationKey
  installationId = 'installation-device-a'
  app = @{ version = '1.0.0'; build = '1'; platform = 'android' }
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Method Post -ContentType 'application/json' -Uri http://127.0.0.1:8787/api/v1/licensing/activate -Body $activate
```

Troque o `installationId` para `installation-device-b` e repita. Com `maxDevices = 1`, o segundo aparelho deve receber `DEVICE_LIMIT_REACHED` até a instalação A ser desativada.

## Estado atual da EP25

Já existem:
- persistência JSON local;
- painel BOECKER;
- criação de clientes e licenças;
- gestão de instalações;
- assinatura Ed25519;
- chave pública raw para pinagem no APK;
- `activate`, `validate`, `refresh` e `deactivate`;
- limite de dispositivos;
- suspensão/revogação administrativa;
- auditoria básica;
- proteção administrativa quando há exposição direta.

Antes de produção ainda serão necessários, entre outros: PostgreSQL/transações reais, autenticação administrativa adequada, rate limiting, gestão segura da chave privada, HTTPS de produção e testes de carga/concorrência.
