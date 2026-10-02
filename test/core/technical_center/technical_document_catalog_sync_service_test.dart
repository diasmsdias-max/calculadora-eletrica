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
        checksum: 'same-checksum',
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
          checksum: 'same-checksum',
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

  test('checksum change requests cleanup of stale physical copy', () async {
    final repository = MemoryRepository();
    const stale = TechnicalDocument(
      id: 'weg-cfw500',
      title: 'Manual antigo',
      category: TechnicalDocumentCategory.manufacturerManual,
      checksum: 'old-checksum',
      availability: TechnicalDocumentAvailability.downloaded,
      localPath: '/local/manual.pdf',
      keepOffline: true,
    );
    await repository.save(stale);
    TechnicalDocument? invalidated;
    final service = TechnicalDocumentCatalogSyncService(
      repository: repository,
      source: CatalogSource([
        const TechnicalDocument(
          id: 'weg-cfw500',
          title: 'Manual revisão nova',
          category: TechnicalDocumentCategory.manufacturerManual,
          checksum: 'new-checksum',
        ),
      ]),
      onInvalidatedOfflineCopy: (document) async {
        invalidated = document;
      },
    );

    await service.sync();

    expect(invalidated?.id, 'weg-cfw500');
    expect(invalidated?.localPath, '/local/manual.pdf');
  });

  test('catalog checksum change invalidates stale offline copy', () async {
    final repository = MemoryRepository();
    await repository.save(
      const TechnicalDocument(
        id: 'weg-cfw500',
        title: 'Manual antigo',
        category: TechnicalDocumentCategory.manufacturerManual,
        checksum: 'old-checksum',
        availability: TechnicalDocumentAvailability.downloaded,
        localPath: '/local/manual.pdf',
        keepOffline: true,
      ),
    );
    final service = TechnicalDocumentCatalogSyncService(
      repository: repository,
      source: CatalogSource([
        const TechnicalDocument(
          id: 'weg-cfw500',
          title: 'Manual revisão nova',
          category: TechnicalDocumentCategory.manufacturerManual,
          remotePath: 'docs/weg/cfw500.pdf',
          fileName: 'cfw500.pdf',
          checksum: 'new-checksum',
        ),
      ]),
    );

    await service.sync();
    final saved = await repository.getById('weg-cfw500');

    expect(saved?.title, 'Manual revisão nova');
    expect(saved?.checksum, 'new-checksum');
    expect(saved?.availability, TechnicalDocumentAvailability.remoteOnly);
    expect(saved?.localPath, isNull);
    expect(saved?.keepOffline, isFalse);
  });


  test('removes stale remote-only entries missing from catalog', () async {
    final repository = MemoryRepository();
    await repository.save(
      const TechnicalDocument(
        id: 'removed',
        title: 'Manual removido',
        category: TechnicalDocumentCategory.manufacturerManual,
      ),
    );
    final service = TechnicalDocumentCatalogSyncService(
      repository: repository,
      source: CatalogSource(const []),
    );

    await service.sync();

    expect(await repository.getById('removed'), isNull);
  });

  test('keeps downloaded entries even when removed from remote catalog', () async {
    final repository = MemoryRepository();
    await repository.save(
      const TechnicalDocument(
        id: 'offline',
        title: 'Manual offline',
        category: TechnicalDocumentCategory.manufacturerManual,
        availability: TechnicalDocumentAvailability.downloaded,
        localPath: '/local/manual.pdf',
      ),
    );
    final service = TechnicalDocumentCatalogSyncService(
      repository: repository,
      source: CatalogSource(const []),
    );

    await service.sync();

    expect(await repository.getById('offline'), isNotNull);
  });

}
