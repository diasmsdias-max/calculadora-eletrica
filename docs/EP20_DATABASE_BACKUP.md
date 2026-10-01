# EP20 — Banco de Dados V2 e Backup Manual

Status: Implementação concluída — aguardando validação final/merge  
Base: EP19 integrada em `develop` (`bea55ac`)  
Branch: `feature/ep20-database-backup`

## Objetivo

Criar a camada de persistência preparada para o fluxo Profissional sem quebrar os projetos e registros da V1, além de implementar o contrato de backup manual versionado do VIS ELECTRICA.

## Princípios

- offline-first;
- os seis motores V1 não serão reescritos;
- dados V1 existentes não podem ser perdidos;
- acesso a dados deve passar por repositórios, evitando acoplamento da UI ao mecanismo físico;
- migração deve ser idempotente e recuperável;
- licença, tokens e credenciais nunca fazem parte do backup;
- backup continua permitido mesmo sem licença Profissional ativa.

## Modelo de persistência V2

A persistência relacional deve estar preparada para:

`Cliente/Instalação → Projeto → Cargas → Circuitos → Quadros → Proteções → Materiais`

Nesta EP não será implementada a lógica funcional completa desses módulos. A EP20 cria a fundação de armazenamento e migração que as próximas EPs utilizarão.

### Entidades-base previstas

- projeto;
- cliente/instalação;
- carga;
- circuito;
- quadro;
- proteção;
- item de material;
- metadados/migração.

Identificadores devem ser estáveis e independentes de posição em listas.

## Compatibilidade V1

Os projetos atuais usam a persistência legada e devem continuar abrindo normalmente.

A migração V1 → V2 deve:

1. detectar dados legados;
2. preservar IDs e dados técnicos sempre que possível;
3. executar uma única vez por versão de migração;
4. não apagar a origem antes da validação da gravação V2;
5. permitir recuperação em caso de falha;
6. possuir testes com dados V1 reais/representativos.

## Backup manual

Entrada prevista:

`Configurações → Dados e Backup`

Ações:

- Criar backup;
- Restaurar backup.

O arquivo deve usar extensão própria, por exemplo `.visbackup`, com conteúdo estruturado e versionado.

### Envelope mínimo

- formato/assinatura VIS ELECTRICA;
- versão do formato;
- data de criação;
- versão do aplicativo;
- payload dos dados exportáveis;
- informação de integridade.

### Incluído

- projetos e dados técnicos;
- Perfil Profissional;
- preferências exportáveis definidas pelo contrato:
  - módulos V1 visíveis na tela principal;
  - visibilidade do módulo Profissional.

Essas preferências são somente de interface. Estado de licença/ativação não é inferido, exportado ou restaurado.

### Excluído obrigatoriamente

- estado da licença;
- chave de ativação;
- tokens;
- credenciais;
- segredos de autenticação;
- flags exclusivas de desenvolvimento.

## Restauração inicial

Nesta EP, a restauração será do tipo **substituir dados locais**, mediante confirmação explícita do usuário.

Fluxo:

`Selecionar arquivo → validar formato/versão/integridade → mostrar aviso → restaurar → validar → confirmar sucesso`

Merge inteligente entre backups fica fora do escopo inicial.

## Novo aparelho

Fluxo esperado:

`Instalar → Ativar licença (quando aplicável) → Restaurar backup → Recuperar projetos/perfil`

A licença não é restaurada pelo arquivo.

## Critérios de aceite

1. EP19 e todos os testes V1 permanecem verdes.
2. Persistência V2 fica isolada por repositórios.
3. Existe estratégia testada de compatibilidade/migração V1.
4. Backup possui formato e versão identificáveis.
5. Backup não contém licença, tokens ou credenciais.
6. Perfil Profissional pode ser incluído.
7. Backup pode ser criado sem licença Profissional ativa.
8. Arquivo inválido/corrompido é rejeitado sem destruir dados locais.
9. Restauração exige confirmação antes de substituir dados.
10. Falha de restauração não deixa estado parcialmente aplicado.
11. Estrutura fica preparada para Cargas → Circuitos → Quadros das EPs seguintes.

## Evidências de aceite

- [x] 1. EP19 e regressão V1 verdes na Flutter CI.
- [x] 2. Persistência V2 isolada por repositórios SQLite.
- [x] 3. Migração V1 → V2 idempotente e coberta por testes.
- [x] 4. Envelope `.visbackup` possui assinatura, versão, data, versão do app e SHA-256 de integridade.
- [x] 5. Licença, chave, tokens, credenciais e `app_metadata` sensível ficam fora do backup.
- [x] 6. Perfil Profissional é exportável/restaurável.
- [x] 7. Criação de backup não depende de licença Profissional ativa.
- [x] 8. Formato, integridade, referências e preferências inválidas são rejeitados antes da substituição.
- [x] 9. UI exige confirmação explícita antes da restauração.
- [x] 10. SQLite restaura em transação; Perfil Profissional e preferências usam snapshot + rollback compensatório.
- [x] 11. Schema V2 já reserva Cargas, Circuitos, Quadros, Proteções e Materiais para as próximas EPs.

Última validação funcional da implementação: Flutter CI #245 — sucesso.

## Fora do escopo

- compra/licenciamento comercial definitivo;
- sincronização em nuvem;
- backup automático;
- merge entre dois conjuntos de dados;
- implementação completa de Cargas/Circuitos/Quadros/Proteções/Materiais;
- alteração dos cálculos V1.
