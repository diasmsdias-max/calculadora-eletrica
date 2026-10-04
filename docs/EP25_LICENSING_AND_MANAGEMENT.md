# EP25 — Licenciamento e Gestão VIS

## Objetivo
Criar a infraestrutura comercial e técnica de licenciamento do VIS ELECTRICA sem reabrir a V1 e sem colocar segredos de licenciamento no APK.

A EP25 deve permitir o teste físico completo: cadastrar cliente no painel, emitir licença, ativar um aparelho, liberar o módulo Profissional e manter funcionamento offline controlado.

## Princípios
- O servidor é a autoridade sobre cliente, plano, licença, dispositivos, permissões, validade e revogação.
- Assumir que um atacante pode possuir e inspecionar o APK completo.
- A chave privada de assinatura nunca entra no aplicativo.
- O APK contém apenas material público necessário para validar credenciais assinadas.
- Nenhuma senha mestre, credencial administrativa, segredo do banco ou token mestre pode ser embutido no APK.
- Licença e credenciais não fazem parte do backup `.visbackup`.
- Falha/expiração do Profissional não deve apagar projetos ou dados do usuário.
- Distribuição direta por APK deve continuar possível.
- HTTPS é obrigatório em produção.

## Componentes
1. Painel Administrativo VIS.
2. API de Licenciamento VIS.
3. Persistência do servidor.
4. License Manager no aplicativo.
5. Credencial offline assinada.
6. Configuração comercial remota com fallback local.

## Modelo mínimo de dados

### Cliente
- id
- nome
- empresa
- CPF/CNPJ opcional
- telefone
- e-mail
- observações
- status
- createdAt / updatedAt

### Plano
- id
- nome
- duração/validade comercial
- limite padrão de dispositivos
- permissões/módulos
- status

### Licença
- id
- customerId
- planId
- activationKeyHash
- status: ACTIVE, SUSPENDED, REVOKED, EXPIRED
- validFrom / validUntil
- maxDevices
- permissions
- createdAt / updatedAt

A chave de ativação em texto puro não deve ser armazenada como credencial recuperável no banco. Ela é apresentada no momento apropriado e o servidor mantém representação segura para validação.

### Instalação
- id
- licenseId
- installationId
- nome amigável/modelo quando disponível e não sensível
- status: ACTIVE, DEACTIVATED, REVOKED
- activatedAt
- lastSeenAt
- deactivatedAt

O `installationId` é aleatório, criptograficamente forte e criado na primeira instalação. Não usar IMEI como identidade da licença.

### Auditoria
Registrar operações administrativas e de licenciamento relevantes: criação, ativação, renovação, suspensão, revogação, transferência e alterações de limite/permissões.

## Fluxo de ativação
1. Usuário informa a chave no VIS.
2. App envia chave + installationId + metadados mínimos da versão.
3. Servidor valida licença, validade, status e limite de dispositivos.
4. Se a mesma instalação já estiver ativa, a operação deve ser idempotente.
5. Se houver vaga, servidor registra a instalação.
6. Servidor devolve credencial/licença assinada com permissões e prazo offline.
7. App valida a assinatura e libera somente as permissões concedidas.
8. Se o limite estiver atingido, a nova instalação não é ativada.

## Funcionamento offline
A validade comercial da assinatura e a autorização offline são conceitos diferentes.

Valor inicial adotado para a autorização offline: **7 dias**, configurável pelo servidor.

Enquanto houver conexão, o VIS renova silenciosamente a autorização. Um dispositivo desativado enquanto estiver offline pode funcionar somente até o fim da credencial offline já emitida; ao reconectar, a revogação deve ser aplicada.

Expiração/revogação do Profissional não apaga dados. Recursos gratuitos continuam disponíveis e dados profissionais existentes devem ser preservados.

## Troca de aparelho
Para licença de 1 dispositivo:
- aparelho A ativo => 1/1;
- aparelho B não pode ser ativado enquanto A ocupar a vaga;
- administrador desativa A;
- B pode ser ativado;
- A online perde autorização na próxima validação;
- A offline perde autorização no máximo ao expirar sua credencial offline.

Transferência pelo próprio cliente pode ser adicionada posteriormente com política de frequência; não é requisito para a primeira entrega.

## Contrato inicial da API
Base prevista: `/api/v1/licensing/`

Endpoints funcionais a especificar/implementar:
- `POST activate`
- `POST refresh`
- `POST validate`
- `POST deactivate`

Operações administrativas ficam autenticadas e separadas das operações do aplicativo.

Requisitos:
- HTTPS;
- respostas versionadas;
- proteção contra replay onde aplicável;
- rate limiting no servidor de produção;
- logs/auditoria sem registrar segredos;
- erros não devem revelar dados de outros clientes/licenças.

## Assinatura criptográfica
Usar assinatura assimétrica adequada à plataforma. A chave privada fica exclusivamente no servidor; o app recebe a chave pública.

A credencial assinada deve vincular, no mínimo:
- versão do contrato;
- licenseId;
- installationId;
- plano/permissões;
- issuedAt;
- offlineValidUntil;
- validade comercial relevante.

Alterar localmente esses dados invalida a assinatura.

## Painel Administrativo VIS — primeira versão
Seções:
- Dashboard
- Clientes
- Licenças
- Dispositivos
- Planos
- Auditoria

Fluxo mínimo:
`Novo cliente → gerar licença → definir plano/validade/limite/permissões → entregar chave → acompanhar dispositivos`.

Ações mínimas:
- cadastrar/editar cliente;
- gerar licença;
- suspender/reativar/revogar quando permitido;
- renovar validade;
- alterar limite conforme regra administrativa;
- visualizar dispositivos;
- desativar dispositivo para transferência;
- visualizar auditoria.

## Tela “Ativar VIS ELECTRICA Profissional”
Deve conter:
- campo de chave;
- ação Ativar;
- estados de carregamento/erro/sucesso;
- informações da licença ativa;
- contato comercial.

### Contato comercial
Exibir opção clara “Falar pelo WhatsApp” para quem ainda não possui licença.

A configuração comercial deve poder vir do servidor (telefone, canal e/ou URL), com fallback seguro embutido no APK. Assim uma troca de número não exige obrigatoriamente nova versão.

Não aceitar do servidor esquemas arbitrários de URL sem validação. Para WhatsApp, normalizar/validar o destino antes de abrir o aplicativo externo.

## Integração com o VIS existente
- Não reabrir cálculos congelados da V1.
- Substituir a decisão provisória de acesso Profissional pelo License Manager.
- Preservar projetos, PDFs, backup e configurações existentes.
- Central Técnica EP24 continua separada e deve ser testada após ativação real.
- Nenhum bypass de desenvolvimento pode vazar para build de produção.

## Cenários obrigatórios de teste
1. Chave válida ativa primeiro aparelho.
2. Reiniciar/fechar app preserva autorização válida.
3. App funciona offline dentro da janela autorizada.
4. Chave inválida é recusada.
5. Licença expirada/suspensa/revogada não recebe nova autorização.
6. Segundo aparelho é recusado quando limite = 1.
7. Desativar primeiro aparelho libera vaga para o segundo.
8. Primeiro aparelho offline não permanece Profissional além de sua credencial offline.
9. Restaurar `.visbackup` em outro aparelho não transfere licença.
10. Alterar payload local invalida assinatura.
11. Falha do servidor não apaga dados locais.
12. Após ativação, módulo Profissional abre e permite testar a Central Técnica EP24.

## Critério de conclusão da EP25
A EP25 só estará pronta para aprovação quando o fluxo real no servidor local permitir:

`Painel → cliente → licença → chave → APK → ativação → registro do aparelho → Profissional liberado → uso offline controlado`.

Após o teste físico do usuário e a validação das ferramentas/interfaces do Profissional, EP24 e EP25 serão avaliadas para merge em `develop`. O merge continua exigindo autorização explícita do usuário.
