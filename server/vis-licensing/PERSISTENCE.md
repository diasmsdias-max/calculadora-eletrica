# Persistência local — EP25

Nesta etapa o bootstrap passa a persistir clientes, planos, licenças, instalações e auditoria em arquivo JSON local, usando gravação temporária + rename para reduzir risco de arquivo parcial.

Padrão:
`.local-data/licensing-v1.json`

Pode ser alterado por:
`VIS_LICENSE_DATA_FILE`

A pasta `.local-data/` está ignorada pelo Git.

## Segurança
- chave de ativação completa não é persistida;
- somente `activationKeyHash` e dica final são armazenados;
- chave privada Ed25519 continua separada;
- arquivo local é apenas a persistência de desenvolvimento.

## Próxima migração
O contrato de persistência foi isolado para permitir substituir esta implementação por PostgreSQL sem mudar a API pública nem o fluxo do aplicativo. O PostgreSQL continua sendo o alvo de produção.

Esta implementação não substitui transações reais do banco para concorrência de produção.
