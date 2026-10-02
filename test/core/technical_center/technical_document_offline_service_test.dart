import 'package:calculadora_eletrica/core/technical_center/technical_document.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document_offline_service.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryRepo implements TechnicalDocumentRepository {
  final map = <String, TechnicalDocument>{};

  @override
  Future<void> save(TechnicalDocument document) async {
    map[document.id] = document;
  }

  @override
  Future<TechnicalDocument?> getById(String id) async => map[id];

  @override
  Future<List<TechnicalDocument>> list() async => map.values.toList();

  @override
  Future<void> delete(String id) async {
    map.remove(id);
  }
}

class Remote implements TechnicalDocumentRemoteSource {
  final List<int> bytes;
  Remote(this.bytes);

  @override
  Future<List<int>> download(String path) async => bytes;
}

class Store implements TechnicalDocumentFileStore {
  final paths = <String>{};

  @override
  Future<String> write({
    required String documentId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final path = '/technical/$documentId/$fileName';
    paths.add(path);
    return path;
  }

  @override
  Future<bool> exists(String path) async => paths.contains(path);

  @override
  Future<void> delete(String path) async {
    paths.remove(path);
  }
}

void main() {
  test('download validates and persists offline metadata', () async {
    final repo = MemoryRepo();
    final store = Store();
    final service = TechnicalDocumentOfflineService(
      repository: repo,
      remote: Remote([1, 2, 3]),
      files: store,
      checksum: (_) => 'ok',
    );
    const document = TechnicalDocument(
      id: 'd1',
      title: 'Manual',
      category: TechnicalDocumentCategory.manufacturerManual,
      remotePath: 'manual.pdf',
      fileName: 'manual.pdf',
      checksum: 'ok',
    );

    final saved = await service.download(document, keepOffline: true);

    expect(saved.isAvailableOffline, isTrue);
    expect(saved.keepOffline, isTrue);
    expect(saved.sizeBytes, 3);
    expect(await service.validateLocalCopy(saved), isTrue);
  });

  test('checksum mismatch rejects document before local write', () async {
    final repo = MemoryRepo();
    final store = Store();
    final service = TechnicalDocumentOfflineService(
      repository: repo,
      remote: Remote([1]),
      files: store,
      checksum: (_) => 'wrong',
    );
    const document = TechnicalDocument(
      id: 'd1',
      title: 'Manual',
      category: TechnicalDocumentCategory.manufacturerManual,
      remotePath: 'manual.pdf',
      fileName: 'manual.pdf',
      checksum: 'expected',
    );

    expect(() => service.download(document), throwsStateError);
    expect(store.paths, isEmpty);
  });

  test('remove local copy returns catalog entry to remote only', () async {
    final repo = MemoryRepo();
    final store = Store();
    final service = TechnicalDocumentOfflineService(
      repository: repo,
      remote: Remote([1]),
      files: store,
      checksum: (_) => 'ok',
    );
    const document = TechnicalDocument(
      id: 'd1',
      title: 'Manual',
      category: TechnicalDocumentCategory.manufacturerManual,
      remotePath: 'manual.pdf',
      fileName: 'manual.pdf',
    );

    final downloaded = await service.download(document);
    final remoteDocument = await service.removeLocalCopy(downloaded);

    expect(
      remoteDocument.availability,
      TechnicalDocumentAvailability.remoteOnly,
    );
    expect(remoteDocument.localPath, isNull);
  });
}
