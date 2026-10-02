import 'technical_document.dart';
import 'technical_document_repository.dart';

abstract class TechnicalDocumentRemoteSource {
  Future<List<int>> download(String remotePath);
}

abstract class TechnicalDocumentFileStore {
  Future<String> write({
    required String documentId,
    required String fileName,
    required List<int> bytes,
  });

  Future<bool> exists(String localPath);

  Future<void> delete(String localPath);
}

class TechnicalDocumentOfflineService {
  final TechnicalDocumentRepository repository;
  final TechnicalDocumentRemoteSource remote;
  final TechnicalDocumentFileStore files;
  final String Function(List<int>) checksum;

  const TechnicalDocumentOfflineService({
    required this.repository,
    required this.remote,
    required this.files,
    required this.checksum,
  });

  Future<TechnicalDocument> download(
    TechnicalDocument document, {
    bool keepOffline = false,
  }) async {
    final normalized = document.normalized();
    if (normalized.remotePath.isEmpty) {
      throw StateError('Document has no remote path.');
    }
    if (normalized.fileName.isEmpty) {
      throw StateError('Document has no file name.');
    }

    final bytes = await remote.download(normalized.remotePath);
    if (bytes.isEmpty) {
      throw StateError('Downloaded document is empty.');
    }

    final actualChecksum = checksum(bytes);
    if (normalized.checksum.isNotEmpty &&
        actualChecksum.toLowerCase() != normalized.checksum.toLowerCase()) {
      throw StateError(
        'Downloaded document checksum does not match catalog.',
      );
    }

    final localPath = await files.write(
      documentId: normalized.id,
      fileName: normalized.fileName,
      bytes: bytes,
    );
    final now = DateTime.now().toUtc();
    final saved = TechnicalDocument(
      id: normalized.id,
      title: normalized.title,
      category: normalized.category,
      manufacturer: normalized.manufacturer,
      equipmentType: normalized.equipmentType,
      model: normalized.model,
      description: normalized.description,
      remotePath: normalized.remotePath,
      fileName: normalized.fileName,
      mimeType: normalized.mimeType,
      checksum: normalized.checksum.isEmpty
          ? actualChecksum
          : normalized.checksum,
      sizeBytes: bytes.length,
      availability: TechnicalDocumentAvailability.downloaded,
      localPath: localPath,
      keepOffline: keepOffline,
      publishedAt: normalized.publishedAt,
      downloadedAt: now,
      updatedAt: normalized.updatedAt,
    );
    await repository.save(saved);
    return saved;
  }

  Future<TechnicalDocument> removeLocalCopy(
    TechnicalDocument document,
  ) async {
    final normalized = document.normalized();
    final localPath = normalized.localPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        await files.exists(localPath)) {
      await files.delete(localPath);
    }

    final saved = TechnicalDocument(
      id: normalized.id,
      title: normalized.title,
      category: normalized.category,
      manufacturer: normalized.manufacturer,
      equipmentType: normalized.equipmentType,
      model: normalized.model,
      description: normalized.description,
      remotePath: normalized.remotePath,
      fileName: normalized.fileName,
      mimeType: normalized.mimeType,
      checksum: normalized.checksum,
      sizeBytes: normalized.sizeBytes,
      availability: TechnicalDocumentAvailability.remoteOnly,
      keepOffline: false,
      publishedAt: normalized.publishedAt,
      updatedAt: normalized.updatedAt,
    );
    await repository.save(saved);
    return saved;
  }

  Future<bool> validateLocalCopy(TechnicalDocument document) async {
    final normalized = document.normalized();
    final localPath = normalized.localPath;
    final valid =
        normalized.availability == TechnicalDocumentAvailability.downloaded &&
        localPath != null &&
        localPath.isNotEmpty &&
        await files.exists(localPath);
    if (valid) return true;

    if (normalized.availability == TechnicalDocumentAvailability.downloaded) {
      await repository.save(
        TechnicalDocument(
          id: normalized.id,
          title: normalized.title,
          category: normalized.category,
          manufacturer: normalized.manufacturer,
          equipmentType: normalized.equipmentType,
          model: normalized.model,
          description: normalized.description,
          remotePath: normalized.remotePath,
          fileName: normalized.fileName,
          mimeType: normalized.mimeType,
          checksum: normalized.checksum,
          sizeBytes: normalized.sizeBytes,
          availability: TechnicalDocumentAvailability.remoteOnly,
          keepOffline: false,
          publishedAt: normalized.publishedAt,
          updatedAt: normalized.updatedAt,
        ),
      );
    }
    return false;
  }
}
