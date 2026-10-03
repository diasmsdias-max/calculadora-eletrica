# VIS Licensing Server — bootstrap local

Primeira implementação executável da EP25. Usa somente módulos nativos do Node.js e mantém dados em memória **apenas para desenvolvimento**.

## Executar
Requer Node.js 20+.

```powershell
cd server/vis-licensing
npm start
```

Por padrão escuta somente `127.0.0.1:8787`. Não expor este bootstrap na LAN/Internet: os endpoints administrativos ainda não possuem autenticação e o transporte deste bootstrap é HTTP local.

## Teste rápido
Health:
```powershell
Invoke-RestMethod http://127.0.0.1:8787/health
```

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

A resposta de criação mostra a chave completa uma vez. O servidor persiste somente SHA-256 + dica final.

Ativar:
```powershell
$activate = @{
  contractVersion = 1
  activationKey = $license.activationKey
  installationId = 'installation-device-a'
  app = @{ version = '1.0.0'; build = '1'; platform = 'android' }
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Method Post -ContentType 'application/json' -Uri http://127.0.0.1:8787/api/v1/licensing/activate -Body $activate
```

Troque `installationId` por `installation-device-b` e repita: com limite 1, deve retornar `DEVICE_LIMIT_REACHED`.

## Limitações intencionais desta etapa
- armazenamento em memória;
- HTTP somente em loopback;
- sem painel;
- sem autenticação administrativa;
- sem credencial assinada;
- sem refresh/validate/deactivate.

Esses itens são etapas seguintes da EP25. Este bootstrap não é servidor de produção.
