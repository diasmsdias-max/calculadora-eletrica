# EP25 — Modelo de Persistência do Servidor VIS (v1)

Modelo relacional inicial para o servidor de licenciamento. A implementação pode usar PostgreSQL em produção e uma base local compatível durante desenvolvimento, sem alterar o contrato da API.

## customers
- `id` UUID PK
- `name` text NOT NULL
- `company_name` text NULL
- `document` text NULL
- `phone` text NULL
- `email` text NULL
- `notes` text NULL
- `status` text NOT NULL
- `created_at` timestamptz NOT NULL
- `updated_at` timestamptz NOT NULL

## plans
- `id` UUID PK
- `code` text UNIQUE NOT NULL
- `name` text NOT NULL
- `default_max_devices` integer NOT NULL CHECK > 0
- `offline_days` integer NOT NULL DEFAULT 7 CHECK > 0
- `permissions` jsonb NOT NULL
- `status` text NOT NULL
- `created_at` / `updated_at`

## licenses
- `id` UUID PK
- `customer_id` UUID FK customers NOT NULL
- `plan_id` UUID FK plans NOT NULL
- `activation_key_hash` text UNIQUE NOT NULL
- `activation_key_hint` text NULL
- `status` text NOT NULL
- `valid_from` timestamptz NOT NULL
- `valid_until` timestamptz NOT NULL
- `max_devices` integer NOT NULL CHECK > 0
- `permissions_override` jsonb NULL
- `created_at` / `updated_at`

Nunca persistir a chave de ativação completa em texto puro. `activation_key_hint` serve somente para identificação administrativa não sensível.

## installations
- `id` UUID PK
- `license_id` UUID FK licenses NOT NULL
- `installation_id_hash` text NOT NULL
- `installation_id_hint` text NULL
- `device_label` text NULL
- `app_version` text NULL
- `app_build` text NULL
- `status` text NOT NULL
- `activated_at` timestamptz NOT NULL
- `last_seen_at` timestamptz NOT NULL
- `deactivated_at` timestamptz NULL
- UNIQUE(`license_id`, `installation_id_hash`)

O identificador bruto recebido não precisa ser exposto no painel. A comparação pode usar representação derivada apropriada no servidor.

## audit_events
- `id` UUID PK
- `occurred_at` timestamptz NOT NULL
- `actor_type` text NOT NULL
- `actor_id` text NULL
- `action` text NOT NULL
- `customer_id` UUID NULL
- `license_id` UUID NULL
- `installation_id` UUID NULL
- `metadata` jsonb NOT NULL DEFAULT '{}'

Não colocar activationKey, credenciais assinadas completas, tokens administrativos ou chave privada em `metadata`.

## signing_keys
Metadados públicos/operacionais das chaves podem ser persistidos:
- `key_id` text PK
- `algorithm` text NOT NULL
- `public_key` text NOT NULL
- `status` text NOT NULL
- `created_at`
- `retired_at` NULL

A **chave privada não pertence ao banco de aplicação em texto puro**. Em desenvolvimento pode ser carregada de arquivo/segredo fora do repositório; em produção deve vir de secret store/HSM/KMS ou mecanismo equivalente.

## commercial_config
- `id` singleton/versionado
- `channel`
- `phone_e164`
- `message`
- `updated_at`

## Índices mínimos
- customers(status)
- licenses(customer_id)
- licenses(status, valid_until)
- installations(license_id, status)
- installations(last_seen_at)
- audit_events(occurred_at)
- audit_events(license_id, occurred_at)

## Regra transacional de ativação
A ativação de uma nova instalação deve bloquear/serializar a decisão referente à licença:
1. carregar licença para atualização;
2. verificar status/validade;
3. procurar a mesma instalação;
4. se já ACTIVE, tratar como idempotente;
5. contar instalações ACTIVE;
6. comparar com `max_devices`;
7. inserir/reativar somente se houver vaga;
8. registrar auditoria;
9. commit;
10. emitir resposta assinada.

Isso evita que duas requisições concorrentes transformem uma licença 1/1 em 2/1.

## Dados seed de desenvolvimento
O ambiente local pode criar explicitamente:
- plano `professional`, limite padrão 1, offline 7 dias;
- configuração comercial de teste;
- administrador inicial por mecanismo de bootstrap seguro.

Cliente e licença de teste devem preferencialmente ser criados pelo painel/API administrativa para que o próprio fluxo administrativo seja validado.

## Migrações
Toda alteração de schema deve ser versionada e reproduzível. Não depender de edição manual do banco para subir um servidor novo.
