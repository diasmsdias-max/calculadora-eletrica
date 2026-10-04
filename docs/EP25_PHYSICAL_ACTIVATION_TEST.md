# EP25 — Teste físico de ativação no Android

Este procedimento prepara o primeiro teste físico do licenciamento VIS sem expor o painel BOECKER, sem versionar segredos e sem relaxar HTTPS.

## Endereços desta estação de teste

- IPv4 LAN: `192.168.1.140`
- painel BOECKER local: `http://127.0.0.1:8787/admin-ui/`
- API pública do APK: `https://192.168.1.140:8444/api/v1/licensing/`
- Central Técnica: `https://192.168.1.140:8443/`

Se o IPv4 mudar, regenere o certificado TLS com SAN para o novo IP e substitua os endereços usados abaixo.

## 1. Preparar a chave de assinatura

Na raiz do repositório:

```powershell
node .\server\vis-licensing\tools\generate-dev-signing-key.js
```

A chave privada fica em `server\vis-licensing\.local-secrets\vis-license-ed25519.pem`, pasta ignorada pelo Git. O comando recusa sobrescrever uma chave existente. Nunca copie esse arquivo para o Android, APK, commit, mensagem ou backup compartilhado.

## 2. Iniciar backend, painel e gateway HTTPS

Os certificados TLS locais ficam fora do repositório do aplicativo. Com os certificados preparados em `..\certs`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\server\vis-licensing\tools\Start-Ep25LocalServer.ps1
```

O resultado esperado é:

- `127.0.0.1:8787`: backend e painel, acessíveis somente neste computador;
- `0.0.0.0:8444`: gateway TLS que encaminha somente `/api/v1/licensing/`;
- `/admin/*`, `/admin-ui/*` e `/health` retornam 404 no gateway HTTPS.

Teste local:

```powershell
Invoke-RestMethod http://127.0.0.1:8787/health
Invoke-RestMethod http://127.0.0.1:8787/api/v1/licensing/public-key
```

## 3. Liberar somente a porta HTTPS da EP25

Em PowerShell aberto como Administrador:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\server\vis-licensing\tools\New-Ep25FirewallRule.ps1
```

A regra permite somente TCP 8444 vindo de `LocalSubnet`. Nenhuma porta administrativa é aberta.

## 4. Criar cliente e licença pelo painel BOECKER

Abra no computador:

`http://127.0.0.1:8787/admin-ui/`

1. Cadastre o cliente.
2. Gere uma licença do plano Profissional.
3. Use limite de 1 dispositivo no primeiro ciclo.
4. Copie a chave de ativação exibida na criação. A chave completa não é armazenada pelo servidor e não poderá ser recuperada depois.

Os dados locais persistem em `server\vis-licensing\.local-data\licensing-v1.json`, também ignorado pelo Git.

## 5. Obter a chave pública real

```powershell
$keyInfo = Invoke-RestMethod http://127.0.0.1:8787/api/v1/licensing/public-key
$keyInfo | Select-Object keyId, algorithm, publicKeyRawBase64
```

O APK recebe `keyId` e `publicKeyRawBase64`. Ele nunca busca essa rota para decidir dinamicamente em qual chave confiar.

## 6. Preparar Flutter no Windows

Nesta estação, o caminho original do Flutter contém espaços e o hook nativo do SQLite não preserva esse caminho. Crie uma unidade virtual temporária para o mesmo SDK:

```powershell
subst V: "C:\Projetos\BCK Agenda\Flutter SDK\flutter"
V:\bin\flutter.bat --version
```

O Android Studio desta estação usa JDK 25, incompatível com o Gradle 8.14.3 atual. Aponte temporariamente o Flutter para o Microsoft OpenJDK 21 já instalado:

```powershell
V:\bin\flutter.bat config --jdk-dir="C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
```

Para remover a unidade depois do teste:

```powershell
subst V: /D
```

## 7. Gerar o APK de teste

O script sempre gera `--debug`, valida URL, chave pública Ed25519 e certificado, e recusa um arquivo contendo chave privada:

```powershell
.\tools\build_ep25_test_apk.ps1 `
  -LicenseApiBaseUrl "https://192.168.1.140:8444/api/v1/licensing/" `
  -KeyId $keyInfo.keyId `
  -PublicKeyBase64 $keyInfo.publicKeyRawBase64 `
  -CaCertificatePath "..\certs\vis-local-ca.android.crt" `
  -TechnicalCenterBaseUrl "https://192.168.1.140:8443/" `
  -FlutterExecutable "V:\bin\flutter.bat"
```

Saída esperada:

`build\app\outputs\flutter-apk\app-debug.apk`

Depois do build, devolva a escolha do JDK ao modo automático:

```powershell
V:\bin\flutter.bat config --jdk-dir=""
```

`VIS_LICENSE_CA_CERT_BASE64` é aceito somente fora de `dart.vm.product`. Se esse define for passado a um build de produção, o licenciamento permanece não configurado. Nenhuma chave privada é embutida.

## 8. Instalar no Android

Com depuração USB autorizada:

```powershell
adb install -r .\build\app\outputs\flutter-apk\app-debug.apk
```

Alternativamente, copie o APK para o aparelho e instale manualmente. O aparelho deve estar na mesma rede Wi-Fi, sem isolamento de clientes.

Para testar a URL pelo navegador do aparelho, instale `..\certs\vis-local-ca.android.crt` como certificado de CA e confira a impressão digital com a exibida na geração. O APK de teste já recebe essa CA pública pelo `dart-define`; a instalação no sistema é apenas para o navegador.

## 9. Executar a primeira ativação

1. Abra VIS ELECTRICA.
2. Entre em **Profissional**.
3. Toque em **Ativar VIS ELECTRICA Profissional**.
4. Informe a chave gerada no painel.
5. Confirme a mensagem de sucesso.
6. Abra **Projetos Elétricos** e **Central Técnica VIS**.
7. No painel BOECKER, confirme que o dispositivo foi registrado.

## 10. Persistência e funcionamento offline

1. Feche completamente o aplicativo.
2. Abra novamente e confirme que o módulo continua ativo.
3. Ative modo avião.
4. Feche e reabra o aplicativo.
5. Confirme acesso durante a janela offline assinada.
6. Não altere a data do aparelho: isso não substitui o cenário real de expiração.

A credencial e o `installationId` ficam em armazenamento local separado do `.visbackup`. `android:allowBackup="false"` impede backup Android automático do estado do aplicativo.

## 11. Limite e troca de aparelho

1. Tente a mesma chave em um segundo aparelho com `maxDevices = 1`; deve aparecer **Limite de dispositivos atingido**.
2. No painel, desative o primeiro dispositivo.
3. Ative o segundo aparelho; a vaga deve ser liberada.
4. O primeiro aparelho offline mantém acesso apenas até `offlineValidUntil`; online, não recebe nova autorização.

## 12. Suspensão, expiração e revogação

Use o painel para suspender ou revogar a licença e confirme que `refresh`/`validate` não emitem nova credencial. Para expiração, use uma licença de teste com validade curta controlada pelo servidor. Dados profissionais existentes não devem ser apagados.

## 13. Restauração e adulteração

- Restaurar um `.visbackup` em outro aparelho não transfere a licença, pois a credencial é vinculada ao hash do `installationId` local e não faz parte do pacote.
- Alterar payload ou assinatura da credencial invalida Ed25519 e não libera o módulo.
- Indisponibilidade do servidor não remove projetos nem a credencial local ainda válida.

## 14. Verificações automatizadas

```powershell
V:\bin\flutter.bat analyze
V:\bin\flutter.bat test
node --test .\server\vis-licensing\test\*.test.js
```

## 15. Encerrar

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\server\vis-licensing\tools\Stop-Ep25LocalServer.ps1
```

O servidor da Central Técnica na porta 8443 possui comando de encerramento separado em `..\scripts\Stop-Server.ps1`.

## Checklist obrigatório

- [ ] chave válida ativa o primeiro aparelho;
- [ ] reinício preserva autorização;
- [ ] offline funciona dentro da janela;
- [ ] chave inválida é recusada;
- [ ] licença expirada, suspensa ou revogada não renova;
- [ ] segundo aparelho é recusado com limite 1;
- [ ] desativar o primeiro libera o segundo;
- [ ] primeiro aparelho não passa de `offlineValidUntil`;
- [ ] `.visbackup` não transfere licença;
- [ ] payload adulterado é recusado;
- [ ] falha do servidor não apaga dados;
- [ ] Central Técnica abre após ativação.
