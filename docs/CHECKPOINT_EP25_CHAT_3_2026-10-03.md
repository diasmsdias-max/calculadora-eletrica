# CHECKPOINT — EP25 Chat #3 — 2026-10-03

## Estado oficial

- Repositório: `diasmsdias-max/calculadora-eletrica`
- Branch: `feature/ep25-licensing-foundation`
- PR: #15 (Draft → `develop`)
- HEAD: `a2c1109e59f5a4904cf1ccd7905913c5550dd43f`
- Último CI: **Flutter CI #463 — SUCCESS**
- Merge: **NÃO realizado / NÃO autorizado**
- `main`: não alterar.
- Documento de produto: `docs/VIS_ELECTRICA_PROFISSIONAL_V2_SPEC.md`

## Entregas estabilizadas neste chat

### 1. Bloqueio transversal de quadro fechado

Criado `ProfessionalClosedBoardGuard`.

Regra consolidada:
- circuito pertencente a quadro fechado continua consultável;
- Circuitos fica somente leitura;
- Dimensionamento fica somente leitura;
- Proteções existentes ficam somente leitura;
- novas proteções não podem selecionar circuito pertencente a quadro fechado;
- mensagem de interface: **“Quadro fechado — reabra o quadro para alterar.”**
- circuito novo continua permitido quando não houver bloqueio de licença.

CI de estabilização: #457 SUCCESS.

Pendência futura relacionada:
- aplicar a mesma proteção em **Cargas** quando uma carga estiver vinculada a circuito pertencente a quadro fechado, pois alterar a carga invalida dados a jusante.

### 2. Integridade do .visproject V2

Foi identificado defeito real no `VisProjectTransferService._db()`: a importação removia a versão do contrato e gravava `contract_version = 1` em todas as entidades.

Corrigido em `57db73e`:
- preserva o `contractVersion` recebido;
- fallback para versão 1 somente quando ausente/legado.

Teste de round-trip V2 adicionado em `fcee995`:
- exporta projeto;
- apaga;
- importa;
- confirma Board V2;
- confirma `status = closed`;
- confirma `closed_at`;
- confirma localização;
- confirma relação quadro → circuito;
- confirma Protection V2;
- confirma role, In adotado, In recomendado, status/critério de validação, polos, curva, capacidade de interrupção e observações.

CI #459 SUCCESS.

### 3. Transferência exposta pela persistência

`V2Persistence` agora fornece `VisProjectTransferService projectTransfer`, reutilizando a mesma conexão SQLite.

Commit: `30ab112`.

A UI não precisa abrir uma segunda conexão nem conhecer detalhes do banco.

### 4. Importar / Exportar projeto

Tela Projetos recebeu:
- ação **Importar projeto** na AppBar;
- seleção limitada a `.visproject`;
- importação via serviço validado;
- mensagens de sucesso / arquivo inválido / falha;
- exportação para `<nome-do-projeto>.visproject`;
- escolha do destino pelo seletor nativo;
- UTF-8 explícito;
- `Uint8List` correto para `FilePicker.saveFile()`.

Correção UTF-8/tipagem: `5b7152a`.

### 5. Menu de toque longo do projeto

Implementado no card:

- **Abrir projeto**
- **Exportar projeto**
- **Deletar projeto**

Commit: `a2c1109`.

IMPORTANTE:
- **Deletar projeto ainda NÃO apaga dados.**
- A opção está visível, mas atualmente informa que a exclusão protegida está em preparação.
- Isso foi intencional para não conectar uma operação destrutiva antes de dupla confirmação + teste transacional.

CI #463 SUCCESS.

## Decisão final da tela Projetos

O card deve mostrar o conteúdo do projeto, e NÃO último backup.

Exemplo:

```
Gramafal
86 cargas • 14 circuitos • 3 quadros
```

Não mostrar:
- “Último backup”
- revisão como informação principal do card.

A busca de projetos permanece.

A tela deve manter **Importar projeto**.

Toque simples: abrir projeto.

Toque longo:
- Abrir projeto
- Exportar projeto
- Deletar projeto

## Exclusão completa — regra obrigatória

A exclusão definitiva ainda precisa ser implementada.

Comportamento aprovado:
1. usuário escolhe **Deletar projeto**;
2. primeiro aviso forte explica que TODO o projeto será apagado;
3. segunda confirmação explícita;
4. somente depois executar a exclusão.

A exclusão deve remover:
- projeto;
- cargas;
- vínculos circuito-carga;
- circuitos;
- vínculos quadro-circuito;
- quadros;
- proteções;
- dimensionamentos;
- materiais;
- memorial;
- demais dados dependentes pertencentes ao projeto.

Mensagem deve deixar claro:
- ação sem volta no app;
- recuperação somente pela importação de um arquivo `.visproject` previamente exportado.

Não exigir que exista backup para permitir apagar, mas advertir fortemente.

A rotina destrutiva deve ser **transacional** e possuir teste automatizado antes de ser ligada ao botão.

## Próxima sequência recomendada — Chat #4

1. Começar do HEAD `a2c1109`.
2. Confirmar CI #463 SUCCESS.
3. Criar serviço/repositório para exclusão completa transacional.
4. Criar teste provando remoção de todo o grafo do projeto sem afetar outro projeto.
5. Implementar as duas confirmações fortes.
6. Conectar a rotina ao menu **Deletar projeto**.
7. Atualizar cards de Projetos para:
   `X cargas • Y circuitos • Z quadros`.
8. Verificar importação/exportação na interface e comportamento de substituição de ID existente.
9. Aplicar guard de quadro fechado às Cargas.
10. Depois retomar pendências técnicas abaixo.

## Pendências técnicas importantes

### Alta prioridade
- exclusão transacional + dupla confirmação;
- resumo de conteúdo nos cards;
- guard de Cargas vinculadas a circuitos de quadro fechado;
- teste de importação/exportação end-to-end da UI quando viável;
- comportamento de importação quando o projeto de mesmo ID já existe deve permanecer claro ao usuário.

### Motor técnico
- `ProfessionalCircuitTechnicalState` ainda usa correspondência de strings para detectar revisão; substituir por estado explícito.
- presença de proteção não deve significar automaticamente circuito completo se `ratedCurrentA` estiver ausente/inválida.
- violação de `Ib ≤ In ≤ Iz` deve resultar em revisão/aviso, mantendo override deliberado.

### Quadros / materiais
- readiness pode gerar consultas repetidas em rebuild; cachear posteriormente.
- IDs do consolidator de materiais dependem da ordem dos grupos; tornar determinísticos.
- fechamento do quadro + substituição de materiais não é transação única entre repositórios.
- decidir/informar comportamento dos materiais gerados ao reabrir quadro.
- proteção geral opcional do quadro ainda não implementada.
- remoção protegida de quadro ainda precisa ser concluída.

### Memorial
- memorial continua por projeto, não por quadro.
- consolidação atual usa entidades do projeto inteiro; evoluir para refletir melhor quadros consolidados/fechados.
- detalhar Ib/In/Iz/cabo quando apropriado.
- limpar casts dinâmicos em `_consolidate()`.
- geração final de Memorial PDF ainda precisa evoluir.
- preservar claramente conteúdo automático versus conteúdo manual.

### Materiais / navegação
- abrir “Materiais” a partir de um quadro fechado atualmente mostra materiais do projeto inteiro; avaliar filtro/contexto por quadro.
- abrir “Memorial” a partir de quadro fechado abre memorial do projeto.

### Infraestrutura
- warnings futuros de Gradle 8.14.3 / AGP 8.11.1 / Kotlin 2.2.20 existem, mas NÃO atualizar oportunisticamente durante EP25 sem necessidade.

## Commits relevantes do Chat #3

- `519f0d5` — closed-board guard
- `e26c382` — teste do guard
- `2df17e0` — remove import não usado
- `bab934f` — lock Circuitos
- `0adf1bd` — lock Dimensionamento
- `759b708` — lock Proteções
- `3dcd8f8` — correção de injeção boardsRepository
- `57db73e` — preserva contractVersion na importação
- `fcee995` — teste round-trip V2
- `30ab112` — projectTransfer na persistência
- `3f00c92` — primeira integração import/export
- `5b7152a` — UTF-8 + Uint8List
- `a2c1109` — menu de toque longo

## Regra de merge

**NÃO MERGEAR.**

O usuário deve autorizar explicitamente qualquer merge.

PR #15 permanece Draft → `develop`.

Após EP25:
- teste de ativação;
- teste físico das ferramentas e interface Profissional;
- correções;
- somente então solicitar autorização explícita para merge.

## Frase de retomada sugerida

No novo chat:

> “Retomar EP25 Chat #4 a partir do checkpoint `docs/CHECKPOINT_EP25_CHAT_3_2026-10-03.md`. Começar pela exclusão transacional de projeto com dupla confirmação. Não fazer merge sem minha autorização.”
