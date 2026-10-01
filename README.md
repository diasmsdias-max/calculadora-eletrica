# BOECKER / VIS ELECTRICA

Aplicativo técnico Android, offline e modular para cálculos elétricos rápidos em campo.

## V1.0.0 — baseline funcional

A V1 foi concluída e validada em aparelho Android real em 30/09/2026. O baseline funcional anterior ao fechamento de versão é o commit `364a701`.

Fluxos validados no aparelho:
- abertura e navegação dos seis módulos;
- cálculos nos módulos;
- criação, salvamento e exclusão de projetos;
- persistência dos cálculos após fechar e reabrir o app;
- consulta dos cálculos salvos;
- configuração de visibilidade dos módulos;
- geração de relatório PDF.

## Módulos V1

- Motor Elétrico
- Transformador
- Motor × Transformador
- Levantamento de Cargas
- Dimensionamento de Cabos
- Queda de Tensão
- Meus Projetos
- Exportação PDF
- Configurações de módulos

## Escopo

O VIS ELECTRICA é uma ferramenta de apoio para cálculos rápidos e análises preliminares em campo. Referências simplificadas e estimativas práticas devem ser confirmadas pelas condições reais da instalação e pelos critérios normativos aplicáveis antes de um dimensionamento definitivo.

## Arquitetura

- `lib/core/calculations` — motores de cálculo
- `lib/core/database` — persistência local
- `lib/core/pdf` — relatórios
- `lib/core/theme` — tema e identidade visual
- `lib/modules` — módulos funcionais
- `test` — testes de cálculos, persistência, PDF, configurações e navegação

## Evolução prevista

A arquitetura permanece preparada para novos módulos, entre eles:
- Circuitos
- Quadros elétricos
- Dimensionamento de disjuntores
- Balanceamento de fases
- DR e DPS
- Alimentadores
- Lista de materiais
- Relatórios técnicos

## Branches

- `main`: versões estáveis
- `develop`: integração e evolução
- branches de feature: alterações isoladas quando necessário

## Build e assinatura

O CI executa análise estática, testes automatizados e gera APK debug para validação. A configuração Android atual ainda usa a chave debug no bloco `release`; uma chave de assinatura de produção deve ser configurada antes de qualquer distribuição pública como APK/AAB de produção.

---
BOECKER / VIS ELECTRICA — V1.0.0
