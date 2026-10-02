import 'technical_document.dart';
import 'technical_document_repository.dart';

abstract class TechnicalDocumentCatalogSource {
  Future<List<TechnicalDocument>> fetchCatalog();
}

class TechnicalDocumentCatalogSyncService {
  final TechnicalDocumentRepository repository;
  final TechnicalDocumentCatalogSource source;

  const TechnicalDocumentCatalogSyncService({
    required this.repository,
    required this.source,
  });

  Future<List<TechnicalDocument>> sync() async {
    final remoteDocuments = await source.fetchCatalog();
    final localDocuments = {
      for (final document in await repository.list()) document.id: document,
    };

    final synced = <TechnicalDocument>[];
    for (final remoteDocument in remoteDocuments) {
      final remote = remoteDocument.normalized();
      final local = localDocuments[remote.id];
      final merged = _mergeRemoteWithLocal(remote, local);
      await repository.save(merged);
      synced.add(merged);
    }
    return synced;
  }

  TechnicalDocument _mergeRemoteWithLocal(
    TechnicalDocument remote,
    TechnicalDocument? local,
  ) {
    if (local == null || !local.isAvailableOffline) {
      return remote;
    }

    final remoteChecksum = remote.checksum.trim().toLowerCase();
    final localChecksum = local.checksum.trim().toLowerCase();
    if (remoteChecksum.isNotEmpty &&
        localChecksum.isNotEmpty &&
        remoteChecksum != localChecksum) {
      return remote;
    }

    return TechnicalDocument(
      id: remote.id,
      title: remote.title,
      category: remote.category,
      manufacturer: remote.manufacturer,
      equipmentType: remote.equipmentType,
      model: remote.model,
      description: remote.description,
      remotePath: remote.remotePath,
      fileName: remote.fileName,
      mimeType: remote.mimeType,
      checksum: remote.checksum,
      sizeBytes: remote.sizeBytes,
      availability: local.availability,
      localPath: local.localPath,
      keepOffline: local.keepOffline,
      publishedAt: remote.publishedAt,
      downloadedAt: local.downloadedAt,
      updatedAt: remote.updatedAt,
    ).normalized();
  }
}
