# EP21 — Núcleo de Projetos Profissionais

Status: Em desenvolvimento  
Base: EP20 integrada em `develop`  
Branch: `feature/ep21-professional-project-core`

## Objetivo

Criar o núcleo do ambiente **VIS ELECTRICA Profissional**, estabelecendo uma fronteira explícita entre as ferramentas rápidas V1 e os Projetos Profissionais, com modelo de dados portátil preparado para futura interoperabilidade Android ↔ Windows.

## Regra estrutural

### Ferramentas rápidas / V1

Os seis módulos V1 continuam independentes, offline e orientados a cálculo rápido em campo:

- Motor Elétrico;
- Transformador;
- Motor × Transformador;
- Levantamento de Cargas;
- Dimensionamento de Cabos;
- Queda de Tensão.

Esses dados não precisam ser tratados pelo futuro VIS ELECTRICA Windows.

### Ambiente Profissional

Somente **Projetos Profissionais** participam do fluxo portátil/multiplataforma.

Fluxo-base previsto:

`Projeto → Cargas → Circuitos → Quadros → Proteções → Dimensionamento → Lista de Materiais → Memorial`

O card Profissional é a porta de entrada do ambiente avançado. A liberação comercial/licença definitiva continua fora do escopo desta EP.

## Filosofia offline-first

O VIS ELECTRICA Profissional não depende de nuvem.

O Android deve permitir:

- criar e editar Projetos Profissionais;
- realizar levantamento em campo;
- concluir projetos pequenos/compatíveis integralmente no aparelho;
- exportar projetos maiores para tratamento em estação Windows no futuro;
- receber novamente um projeto tratado no Windows.

A futura estação Windows deve usar o mesmo modelo conceitual de Projeto Profissional, e não um formato paralelo.

## Projeto portátil

Será reservado o formato de intercâmbio:

`.visproject` — Projeto Profissional VIS ELECTRICA

O `.visproject` é diferente de `.visbackup`:

- `.visbackup`: recuperação/backup do ambiente local;
- `.visproject`: transporte de um Projeto Profissional e suas dependências entre dispositivos/estações.

Nesta EP, o foco é definir o contrato e garantir que IDs/modelos não dependam da interface Android. A experiência Windows não será implementada agora.

## Identidade e versionamento

Todo Projeto Profissional deve possuir:

- ID estável e globalmente transportável;
- versão/revisão do projeto;
- data de criação;
- data da última alteração;
- identificação/nome do projeto;
- dados de cliente/instalação quando disponíveis;
- versão do contrato/modelo;
- origem do último tratamento quando aplicável, sem vincular o projeto a um dispositivo específico.

Entidades futuras (cargas, circuitos, quadros, proteções e materiais) devem usar IDs estáveis e referências explícitas.

## Interoperabilidade futura

O modelo não deve depender de:

- widgets Flutter;
- rotas/telas Android;
- índices de posição em listas;
- caminhos privados do aparelho;
- estado de licença;
- credenciais;
- serviços em nuvem.

## Relação com o Levantamento de Cargas V1

O Levantamento de Cargas V1 permanece uma ferramenta rápida separada.

Futuramente poderá existir a ação:

`Levantamento V1 → Adicionar/Importar para Projeto Profissional`

A importação cria entidades Carga do Projeto Profissional sem alterar o comportamento original da ferramenta V1.

## Critérios de aceite

1. Nenhum dos seis motores/calculadoras V1 é reescrito.
2. Existe conceito persistente de Projeto Profissional separado do projeto/registro legado V1.
3. Projeto Profissional possui ID estável, revisão e timestamps.
4. Modelo de domínio não depende da UI Android.
5. Persistência usa repositório.
6. Estrutura permanece offline-first.
7. Contrato `.visproject` é versionado e identificável.
8. Um projeto pode ser serializado sem licença, tokens ou credenciais.
9. Importação futura Android ↔ Windows pode preservar IDs e relações.
10. Fundação fica preparada para Cargas → Circuitos → Quadros → Proteções → Dimensionamento → Materiais → Memorial.
11. Testes V1 e EP20 permanecem verdes.

## Fora do escopo

- aplicativo Windows;
- sincronização em nuvem;
- sincronização automática entre dispositivos;
- licenciamento comercial definitivo;
- implementação completa de Cargas/Circuitos/Quadros;
- editor Ladder/Industrial;
- importação do Levantamento V1 nesta EP;
- merge inteligente de duas revisões concorrentes do mesmo projeto.
