import 'package:calculadora_eletrica/core/technical_center/technical_document.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document_catalog_sync_service.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRepository implements TechnicalDocumentRepository {
  final documents = <String, TechnicalDocument>{};

  @override
  Future<void> save(TechnicalDocument document) async {
    documents[document.id] = document;
  }

  @override
  Future<TechnicalDocument?> getById(String id) async => documents[id];

  @override
  Future<List<TechnicalDocument>> list() async => documents.values.toList();

  @override
  Future<void> delete(String id) async {
    documents.remove(id);
  }
}

class CatalogSource implements TechnicalDocumentCatalogSource {
  final List<TechnicalDocument> documents;

  CatalogSource(this.documents);

  @override
  Future<List<TechnicalDocument>> fetchCatalog() async => documents;
}

void main() {
  test('adds new remote catalog entries', () async {
    final repository = MemoryRepository();
    final service = TechnicalDocumentCatalogSyncService(
      repository: repository,
      source: CatalogSource([
        const TechnicalDocument(
          id: 'weg-cfw500',
          title: 'Manual CFW500',
          category: TechnicalDocumentCategory.manufacturerManual,
          manufacturer: 'WEG',
        ),
      ]),
    );

    final result = await service.sync();

    expect(result, hasLength(1));
    expect((await repository.getById('weg-cfw500'))?.manufacturer, 'WEG');
  });

  test('catalog refresh preserves downloaded local state', () async {
    final repository = MemoryRepository();
    await repository.save(
      const TechnicalDocument(
        id: 'weg-cfw500',
        title: 'Manual antigo',
        category: TechnicalDocumentCategory.manufacturerManual,
        availability: TechnicalDocumentAvailability.downloaded,
        localPath: '/local/manual.pdf',
        keepOffline: true,
        downloadedAt: null,
      ),
    );
    final service = TechnicalDocumentCatalogSyncService(
      repository: repository,
      source: CatalogSource([
        const TechnicalDocument(
          id: 'weg-cfw500',
          title: 'Manual atualizado',
          category: TechnicalDocumentCategory.manufacturerManual,
          remotePath: 'docs/weg/cfw500.pdf',
          fileName: 'cfw500.pdf',
          checksum: 'new-checksum',
        ),
      ]),
    );

    await service.sync();
    final saved = await repository.getById('weg-cfw500');

    expect(saved?.title, 'Manual atualizado');
    expect(saved?.remotePath, 'docs/weg/cfw500.pdf');
    expect(saved?.availability, TechnicalDocumentAvailability.downloaded);
    expect(saved?.localPath, '/local/manual.pdf');
    expect(saved?.keepOffline, isTrue);
  });
}
