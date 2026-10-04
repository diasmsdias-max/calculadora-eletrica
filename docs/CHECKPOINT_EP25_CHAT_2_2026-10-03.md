# CHECKPOINT - EP25 Chat 2 - 03/10/2026

## Repositorio
- diasmsdias-max/calculadora-eletrica
- branch: feature/ep25-licensing-foundation
- PR #15 continua Draft para develop
- main nao deve ser alterada
- merge nao autorizado

## Teste fisico
- ativacao Profissional em aparelho real: OK
- Perfil Profissional: OK
- identidade EletroAlex aplicada: OK
- Projetos Eletricos abre e permite fluxo: OK
- Central Tecnica abre; catalogo ainda sem documentos no teste
- problemas visuais encontrados: overflow em Estimar FS com teclado e em Nova protecao
- revisar validacao FS e registros incompletos observados em Quadros

## Decisoes consolidadas
1. Tela Profissional ativa sera simplificada: status ativo + Projetos + Central Tecnica + Perfil.
2. Dentro do projeto usar agrupador Cargas, Circuitos e Dimensionamento.
3. Uma carga so pode pertencer a um circuito; um circuito so pode pertencer a um quadro.
4. Cargas registram natureza eletrica quando relevante; informacoes de fases sao herdadas.
5. Protecoes passam a ser sugeridas automaticamente pelo VIS com opcao Aceitar ou Alterar.
6. Criar catalogo comercial para disjuntores, curvas, polos, DR, DPS e bitolas de cabos.
7. Dimensionamento reutiliza dados do circuito e sugere bitola comercial.
8. Quadro tera Fechar quadro. Ao fechar, consolidar protecao geral opcional, materiais e memorial.
9. Quadro fechado oferece Reabrir, Materiais, Memorial e remocao protegida por dupla confirmacao.
10. Materiais sao calculados automaticamente a partir do projeto, com inclusao manual apenas quando necessario.
11. Memorial nasce do quadro consolidado.
12. Tela Projetos tera Importar projeto.
13. Toque prolongado no projeto: Abrir, Exportar, Remover projeto.
14. Exportacao/importacao usa projeto editavel versionado, planejado como .visproject / VIS Project Schema v1.
15. O arquivo deve aceitar projeto incompleto e permitir continuidade futura no VIS Windows.
16. Android e Windows devem compartilhar o mesmo modelo de dados versionado.
17. Alteracoes em dados anteriores invalidam calculos dependentes e exigem revisao/recalculo.

## Documento de produto
A especificacao foi registrada em docs/VIS_ELECTRICA_PROFISSIONAL_V2_SPEC.md e existe documento detalhado gerado no chat.

## Proximo passo
Transformar a especificacao consolidada em plano de implementacao por etapas, corrigindo primeiro integridade/UX e depois Motor Tecnico VIS, fechamento de quadro e importacao/exportacao.

Nao realizar merge sem autorizacao explicita do usuario.
