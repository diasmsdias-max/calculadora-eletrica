# EP19 — Fundação VIS ELECTRICA Profissional

Status: Em desenvolvimento  
Base: VIS ELECTRICA V1.0.0  
Branch: `feature/ep19-professional-foundation`

## Objetivo

Criar a fundação comercial e arquitetural da V2 sem alterar os motores de cálculo validados na V1.

O fluxo profissional futuro será:

`Cliente → Projeto → Cargas → Circuitos → Quadros → Proteções → Materiais → PDF`

## Edições

### Gratuita

Os módulos de cálculo rápido da V1 permanecem disponíveis sem login obrigatório.

### Profissional

A licença Profissional habilita o fluxo de projeto elétrico estruturado e a personalização da identidade profissional.

A arquitetura deve separar:

- preferência de visibilidade do módulo;
- direito de uso (entitlement/licença);
- dados do Perfil Profissional.

## Licenciamento

Requisitos:

- o aplicativo continua prioritariamente offline;
- internet não é necessária para executar cálculos;
- ativação/revalidação da licença pode exigir conexão;
- estado válido deve poder ser armazenado localmente de forma segura;
- o provedor de licença deve ser abstrato para não acoplar a aplicação a um meio de pagamento específico;
- licença, token e credenciais nunca entram no backup;
- perda/inatividade da licença não apaga projetos;
- sem licença ativa, projetos profissionais existentes devem permanecer acessíveis em modo leitura e com possibilidade de backup.

## Perfil Profissional

Disponível com licença Profissional.

Campos iniciais:

- Nome da empresa/profissional: obrigatório;
- CNPJ: opcional;
- Telefone/WhatsApp: opcional.

Regra de marca:

- na edição gratuita permanece a identidade BOECKER / VIS ELECTRICA;
- na edição Profissional o nome configurado substitui BOECKER nos locais previstos;
- VIS ELECTRICA permanece sempre como marca do produto abaixo da identidade do usuário;
- tela principal e PDFs devem consumir uma única fonte de identidade;
- preparar o modelo para logotipo próprio futuramente, sem exigir essa função nesta EP.

O Perfil Profissional é dado do usuário e poderá ser incluído no backup futuro. Ele não representa nem comprova a licença.

## Backup — contrato para EP20

A EP19 deve manter separação suficiente para a EP20 implementar backup manual versionado.

O backup poderá conter:

- projetos;
- cargas/circuitos/quadros e demais dados técnicos futuros;
- preferências aplicáveis;
- Perfil Profissional.

Nunca conterá:

- licença;
- tokens;
- credenciais;
- segredos de autenticação.

A restauração em outro aparelho seguirá:

`Instalar → Ativar licença → Restaurar backup → Recuperar projetos e perfil`

O backup deve continuar disponível mesmo quando a licença Profissional não estiver ativa.

## Compatibilidade V1

É requisito de aceite:

- não reescrever os seis motores de cálculo validados;
- não quebrar projetos/cálculos existentes;
- não quebrar geração de PDF existente;
- não quebrar Configurações de módulos;
- manter funcionamento offline dos recursos atuais;
- manter testes de regressão da V1 no CI.

## Componentes arquiteturais previstos

- `Entitlement`: direitos habilitados;
- `LicenseState`: estado de ativação/validação;
- `LicenseProvider`: contrato abstrato para o mecanismo comercial futuro;
- `ProfessionalProfile`: identidade profissional;
- `BrandIdentity`: resolução da identidade exibida conforme edição/licença;
- `ModulePreferences`: permanece responsável apenas pela visibilidade escolhida pelo usuário.

## Fora do escopo da EP19

- compra/pagamento definitivo;
- servidor comercial definitivo;
- banco relacional V2;
- migração de projetos;
- backup/restauração efetivos;
- Cargas → Circuitos;
- Quadros;
- Proteções;
- Materiais;
- novo PDF profissional completo.

Esses itens entram nas EPs seguintes.

## Critérios de aceite

1. Gratuito continua utilizável sem autenticação obrigatória.
2. Preferência de módulo e licença são independentes.
3. Existe contrato de entitlement para o módulo Profissional.
4. Existe abstração de provedor de licença.
5. Perfil Profissional não armazena dados de autenticação.
6. Identidade padrão continua BOECKER / VIS ELECTRICA.
7. Com entitlement Profissional, a identidade pode usar o nome configurado mantendo VIS ELECTRICA.
8. Estrutura aceita CNPJ e telefone opcionais.
9. Licença não é tratada como dado exportável.
10. A arquitetura prevê modo leitura/backup dos dados profissionais sem licença ativa.
11. Todos os testes de regressão da V1 continuam aprovados.
