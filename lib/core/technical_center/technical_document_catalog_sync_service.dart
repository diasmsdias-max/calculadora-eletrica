import 'technical_document.dart';
import 'technical_document_repository.dart';

abstract class TechnicalDocumentCatalogSource {
  Future<List<TechnicalDocument>> fetchCatalog();
}

class TechnicalDocumentCatalogSyncService {
  final TechnicalDocumentRepository repository;
  final TechnicalDocumentCatalogSource source;
  final Future<void> Function(TechnicalDocument document)?
      onInvalidatedOfflineCopy;

  const TechnicalDocumentCatalogSyncService({
    required this.repository,
    required this.source,
    this.onInvalidatedOfflineCopy,
  });

  Future<List<TechnicalDocument>> sync() async {
    final remoteDocuments = await source.fetchCatalog();
    final localDocuments = {
      for (final document in await repository.list()) document.id: document,
    };

    final synced = <TechnicalDocument>[];
    final remoteIds = <String>{};
    for (final remoteDocument in remoteDocuments) {
      final remote = remoteDocument.normalized();
      remoteIds.add(remote.id);
      final local = localDocuments[remote.id];
      if (_checksumChanged(remote, local) && local != null) {
        await onInvalidatedOfflineCopy?.call(local);
      }
      final merged = _mergeRemoteWithLocal(remote, local);
      await repository.save(merged);
      synced.add(merged);
    }

    for (final local in localDocuments.values) {
      if (!remoteIds.contains(local.id) && !local.isAvailableOffline) {
        await repository.delete(local.id);
      }
    }
    return synced;
  }

  bool _checksumChanged(
    TechnicalDocument remote,
    TechnicalDocument? local,
  ) {
    if (local == null || !local.isAvailableOffline) return false;
    final remoteChecksum = remote.checksum.trim().toLowerCase();
    final localChecksum = local.checksum.trim().toLowerCase();
    return remoteChecksum.isNotEmpty &&
        localChecksum.isNotEmpty &&
        remoteChecksum != localChecksum;
  }

  TechnicalDocument _mergeRemoteWithLocal(
    TechnicalDocument remote,
    TechnicalDocument? local,
  ) {
    if (local == null || !local.isAvailableOffline) {
      return remote;
    }

    if (_checksumChanged(remote, local)) {
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
