# CHECKPOINT — EP25 Chat #4 — 2026-10-04

## Estado do Git
- Repositório: `diasmsdias-max/calculadora-eletrica`
- Branch: `feature/ep25-licensing-foundation`
- PR: #15 — EP25 — Licensing foundation and BOECKER management
- Destino da PR: `develop`
- Regra: NÃO realizar merge sem autorização explícita do usuário.
- `main` não deve ser alterada durante a EP25.

## HEAD no encerramento deste chat
- `0b3622a2b233350bcef05115f8781f1d1ae20597` — `fix(ep25): recalculate overcurrent compliance`
- CI deste commit ainda deve ser verificado no início do próximo chat.
- Último CI confirmado: #516 — SUCCESS para `26051837df97a056d9c5b53d084087dce2e0fb19`.

## Trabalho concluído neste chat

### .visproject
Bloco de endurecimento concluído e CI verde:
- rejeição de project id vazio;
- rejeição de memorial id vazio;
- rejeição de sizing duplicado por circuito;
- rejeição de relações duplicadas circuito-carga e quadro-circuito;
- referências e pertencimento ao projeto validados;
- importação same-id preserva integridade;
- transação e substituição do grafo profissional mantidas.

### Memorial
- Estado explícito quando o quadro solicitado não existe:
  `98fdb8e` — `fix(ep25): show missing board memorial state`.
- Snapshot de um único quadro agora usa contexto do quadro:
  `4f0cac7` — `fix(ep25): contextualize board memorial scope`.
- Testes protegem contexto de quadro versus projeto:
  `a1fd899` — `test(ep25): lock memorial scope context`.
- Conclusões e observações continuam sem preenchimento automático para não inventar interpretação técnica.

### Fechamento/reabertura de quadro
- Serviço já era transacional e preserva materiais manuais na reabertura.
- Adicionada validação imediata de identidade do quadro:
  `fc63b6c` — `fix(ep25): validate board closure identity`.
- Teste garante rejeição de identidade vazia e ausência de alteração no banco:
  `2605183` — `test(ep25): cover invalid board closure identity`.
- Readiness já possui testes para:
  - quadro vazio = pending;
  - circuito pendente = pending;
  - reviewRequired tem prioridade.
- Decisão mantida: o usuário pode `Fechar mesmo assim` quando houver pendências/revisão. Não foi criado campo novo de contrato para registrar fechamento com pendências.

### Integridade técnica Ib/In/Iz
Problema identificado:
- `ProfessionalCircuitTechnicalStateEvaluator` confiava em `validationStatus == nonCompliant`;
- um dado importado/legado poderia informar `compliant` apesar de números incompatíveis.

Correção aplicada no HEAD:
- `0b3622a` — `fix(ep25): recalculate overcurrent compliance`.
- O avaliador agora recalcula numericamente o critério `Ib ≤ In ≤ Iz`.
- Se `In < Ib` ou `In > Iz`, exige revisão independentemente do `validationStatus` persistido.
- `validationStatus == nonCompliant` continua sendo considerado como sinal adicional.

## Próxima ação — início do Chat #5
1. Verificar CI do commit `0b3622a2b233350bcef05115f8781f1d1ae20597`.
2. Se verde, adicionar teste explícito em `test/core/professional/professional_circuit_technical_state_test.dart`:
   - proteção marcada como `compliant`, mas `In < Ib` => `reviewRequired`;
   - proteção marcada como `compliant`, mas `In > Iz` => `reviewRequired`;
   - valores dentro de `Ib ≤ In ≤ Iz` permanecem válidos quando demais requisitos estão completos.
3. Rodar/verificar CI.
4. Continuar inspeção funcional da EP25 antes de ampliar contrato ou escopo.
5. NÃO realizar merge.

## Decisões de produto que permanecem vigentes
- Fluxo Profissional: Projeto → Carga → Circuitos → Quadros → Proteções → Dimensionamento → Lista de Materiais → Memorial.
- NBR como base mínima; override permitido com aviso/revisão.
- Projeto: busca, importação, toque para abrir, long press para Abrir/Exportar/Deletar.
- Exclusão de projeto com aviso forte e duas confirmações.
- Card de projeto mostra somente conteúdo (cargas/circuitos/quadros), sem informação de último backup.
- Backup/exportação manual local; sem nuvem nesta etapa.
- Central Técnica VIS com documentos sob demanda/offline e visualizador PDF interno.
- Não adicionar exclusão de quadro sem decisão explícita de produto.
- Não alterar contratos/banco de forma improvisada apenas para registrar fechamento com pendências.

## Referências principais
- Especificação: `docs/VIS_ELECTRICA_PROFISSIONAL_V2_SPEC.md`
- Checkpoint anterior: `docs/CHECKPOINT_EP25_CHAT_3_2026-10-03.md`
- Este checkpoint: `docs/CHECKPOINT_EP25_CHAT_4_2026-10-04.md`
