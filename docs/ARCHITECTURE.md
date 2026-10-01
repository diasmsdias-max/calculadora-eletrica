# Arquitetura

O app segue organização modular e separa interface, domínio e motores de cálculo.

## Princípios
1. Offline-first.
2. Cálculos independentes da UI.
3. Fórmulas cobertas por testes.
4. Módulos sem dependência circular.
5. Persistência e PDF adicionados por serviços próprios.
6. Expansão prevista para Circuitos e Quadros.

## Camadas
- app: inicialização e navegação.
- core: cálculos, tema, banco e PDF.
- modules: telas e fluxos por ferramenta.
- test: casos de referência e regressão.

## Próximos passos do EP01
- Definir modelos/unidades comuns.
- Criar primeiro motor de cálculo.
- Adicionar testes unitários.
- Preparar persistência local e geração de PDF sem acoplar aos módulos.
