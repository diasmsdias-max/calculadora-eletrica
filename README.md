# Calculadora Elétrica

Aplicativo técnico Android, offline e modular para cálculos elétricos em campo.

## Visão do produto

A V1 será construída em Flutter, com interface dark moderna e intuitiva, armazenamento local de projetos e exportação de relatórios em PDF.

## Módulos V1

- Motor Elétrico
- Transformador
- Motor × Transformador
- Levantamento de Cargas
- Dimensionamento de Cabos
- Queda de Tensão
- Meus Projetos
- Exportação PDF

## Evolução prevista

A arquitetura será preparada para módulos adicionais, incluindo:

- Circuitos
- Quadros elétricos
- Dimensionamento de disjuntores
- Balanceamento de fases
- DR e DPS
- Alimentadores
- Lista de materiais
- Relatórios técnicos

## Arquitetura

A lógica de cálculo será independente da interface para permitir testes unitários e reutilização entre módulos.

Estrutura planejada:

- `lib/core/calculations` — motores de cálculo
- `lib/core/database` — persistência local
- `lib/core/pdf` — relatórios
- `lib/core/theme` — tema e identidade visual
- `lib/modules` — módulos funcionais
- `test/calculations` — validação das fórmulas

## Desenvolvimento

- `main`: versões estáveis
- `develop`: integração e desenvolvimento
- branches de feature: alterações isoladas quando necessário

### EP01 — Fundação

Tema dark, navegação modular, estrutura base e núcleo inicial dos cálculos.

---
Projeto em desenvolvimento.
