# VIS ELECTRICA — Arquitetura, Conceitos e Checkpoint

Data de referência: 01/10/2026

## Visão do produto

VIS ELECTRICA é uma plataforma técnica modular para eletricistas, eletrotécnicos e integradores. O produto preserva uma camada de ferramentas rápidas de campo e desenvolve, em paralelo, um ambiente Profissional preparado para projetos elétricos e futuras aplicações industriais.

## Camada 1 — Ferramentas rápidas

A V1 permanece independente, offline e orientada a cálculos rápidos:
- Motor Elétrico
- Transformador
- Motor × Transformador
- Levantamento de Cargas
- Dimensionamento de Cabos
- Queda de Tensão
- Projetos/registros locais e PDF

Essa camada não precisa participar do futuro intercâmbio com Windows.

## Camada 2 — Profissional

O card Profissional é a entrada para módulos avançados. O primeiro ambiente é Projetos Elétricos:

Projeto → Cargas → Circuitos → Quadros → Proteções → Dimensionamento → Lista de Materiais → Memorial

O Levantamento de Cargas V1 permanece separado. Futuramente poderá importar seus dados para Cargas de um Projeto Profissional.

O ambiente Profissional poderá receber novos módulos. Está prevista uma família Industrial com Ladder, automação, CLPs, IHM, inversores, soft-starters, partidas, redes industriais, diagramas e documentação técnica.

## Android e futura estação Windows

Somente Projetos Profissionais serão preparados para interoperabilidade Android ↔ Windows.

Android:
- coleta/levantamento em campo;
- edição e conclusão de projetos pequenos e médios quando conveniente;
- operação offline e autônoma.

Windows:
- estação de tratamento/projeto para trabalhos mais complexos;
- visualização ampla;
- aplicações e editores mais sofisticados;
- documentação técnica avançada.

Não existe dependência obrigatória de nuvem. O conceito é semelhante a levantamento de topografia: coletar no campo, descarregar na estação, tratar e, quando necessário, retornar o projeto ao dispositivo.

## Formatos

.visbackup:
- backup/restauração do ambiente local;
- versionado e com integridade;
- não contém licença, chave, tokens ou credenciais.

.visproject:
- formato reservado para intercâmbio de um Projeto Profissional;
- deve preservar IDs, relações e revisões;
- futuro transporte Android ↔ Windows sem nuvem obrigatória.

## Estado concluído

V1 foi validada em aparelho real e congelada como VIS ELECTRICA V1.0.0.

EP19: fundação do ambiente Profissional.

EP20: Banco de Dados V2 e Backup Manual.
- integrada em develop pelo PR #10;
- merge commit 02996afe84dd8b1bdc1147a54f64c2e3393a3298;
- CI #246 verde antes do merge;
- 11/11 critérios de aceite atendidos;
- SQLite V2, migração V1, .visbackup, restauração segura, rollback, Perfil Profissional e preferências exportáveis;
- licença/segredos excluídos do backup.

## Em desenvolvimento

EP21 — Núcleo de Projetos Profissionais.
Branch: feature/ep21-professional-project-core.

Objetivos:
- separar Projeto Profissional dos registros/projetos legados V1;
- domínio independente da interface Android;
- IDs estáveis, revisão e timestamps;
- contrato portátil;
- preparar .visproject;
- preparar Cargas → Circuitos → Quadros → Proteções → Dimensionamento → Materiais → Memorial;
- manter V1 intacta.

## Diretrizes permanentes

1. Não reescrever nem quebrar as ferramentas V1.
2. Offline-first.
3. Nuvem não é requisito para funcionamento ou intercâmbio.
4. Somente Projetos Profissionais precisam ser portáveis para Windows.
5. Android deve continuar capaz de finalizar projetos compatíveis com sua interface.
6. Projetos complexos podem ser transferidos para uma estação Windows.
7. Android e Windows devem compartilhar o mesmo modelo conceitual de Projeto Profissional.
8. Dados de domínio não devem depender de widgets Flutter, telas, índices de listas ou caminhos locais.
9. O Profissional deve ser modular e preparado para o futuro ambiente Industrial.
10. Merge em develop somente após critérios/testes e autorização explícita.
