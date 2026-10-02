# Central Técnica VIS — Contrato do servidor

## Objetivo

A Central Técnica VIS usa um catálogo remoto e arquivos técnicos hospedados fora do APK. O aplicativo permanece independente do provedor de hospedagem.

A URL base é fornecida no build:

`--dart-define=VIS_TECHNICAL_CENTER_BASE_URL=https://host-vis.example/`

Produção deve usar HTTPS e um host controlado pelo VIS.

## Estrutura HTTP

A partir da URL base, o cliente espera:

- `technical-documents/catalog.json`
- arquivos referenciados pelo catálogo, por exemplo `technical-documents/files/manual-vis-electrica.pdf`

Os caminhos do catálogo devem ser relativos. URLs absolutas, caminhos iniciados por `/` e caminhos contendo `..` são rejeitados pelo cliente.

## Catálogo

`GET technical-documents/catalog.json`

Resposta: JSON contendo uma lista de documentos no contrato portátil v1.

Campos do documento:

- `contractVersion`: atualmente 1
- `id`: identificador estável e único
- `title`
- `category`: `manufacturerManual`, `controlPanel`, `technicalReference` ou `other`
- `manufacturer`
- `equipmentType`
- `model`
- `description`
- `remotePath`: caminho relativo ao host VIS
- `fileName`
- `mimeType`
- `checksum`: SHA-256 recomendado para todo arquivo publicado
- `sizeBytes`
- `availability`: no catálogo remoto deve ser `remoteOnly`
- `localPath`: null no catálogo remoto
- `keepOffline`: false no catálogo remoto
- `publishedAt`
- `downloadedAt`: null no catálogo remoto
- `updatedAt`

O fixture de referência do piloto está em:
`test/fixtures/technical_documents/catalog.json`.

## Download e integridade

O cliente baixa o `remotePath` pelo mesmo host HTTPS configurado.

Quando `checksum` está presente:
1. o arquivo é baixado;
2. o VIS calcula SHA-256;
3. checksum divergente cancela o download;
4. somente um arquivo válido passa a ser marcado como disponível offline.

Na abertura da Central Técnica, documentos offline são novamente validados. Arquivo ausente ou com checksum divergente volta ao estado remoto e pode ser baixado novamente.

## Atualizações

O `id` deve permanecer estável entre versões do mesmo documento.

Se uma nova versão alterar o arquivo, publique o novo SHA-256 no catálogo. O VIS invalida a cópia offline antiga quando detecta mudança de checksum.

Metadados podem ser atualizados mantendo o mesmo checksum; nesse caso a cópia offline válida é preservada.

## Remoção do catálogo

Documento removido do catálogo remoto:
- sem cópia offline: é removido do catálogo local na sincronização;
- com cópia offline: permanece no aparelho para não retirar inesperadamente material já baixado pelo técnico.

## Piloto

Documento inicial:
- ID: `vis-manual-vis-electrica`
- Título: `Manual do VIS ELECTRICA`
- Categoria: `technicalReference`
- Origem: `VIS ELECTRICA`
- Tipo: `Manual do Aplicativo`
- Arquivo: `Manual_VIS_ELECTRICA.pdf`
- Caminho: `technical-documents/files/manual-vis-electrica.pdf`
- SHA-256: `7d54aa4e53bafcf840f3820cc22c87e3b7f39e5627e2e1b9fa0e1d74689abe80`
- Tamanho: 36872 bytes

O PDF do piloto não deve ser incluído no repositório do aplicativo nem empacotado no APK.

## Teste físico esperado

Com um host HTTPS real configurado:
1. abrir Profissional > Central Técnica VIS;
2. sincronizar;
3. localizar o Manual do VIS ELECTRICA;
4. baixar;
5. abrir no visualizador PDF interno do VIS;
6. remover a cópia local;
7. baixar usando “manter offline”;
8. ativar modo avião;
9. reabrir a Central Técnica e o PDF;
10. reconectar e sincronizar novamente.

A fundação não depende de um provedor específico. Uma migração futura de hospedagem exige apenas mudar a URL base no build, desde que este contrato seja preservado.
