import 'technical_document.dart';
import 'technical_document_repository.dart';

abstract class TechnicalDocumentRemoteSource {
  Future<List<int>> download(String remotePath);
}

abstract class TechnicalDocumentFileStore {
  Future<String> write({required String documentId, required String fileName, required List<int> bytes});
  Future<bool> exists(String localPath);
  Future<void> delete(String localPath);
}

class TechnicalDocumentOfflineService {
  final TechnicalDocumentRepository repository;
  final TechnicalDocumentRemoteSource remote;
  final TechnicalDocumentFileStore files;
  final String Function(List<int>) checksum;

  const TechnicalDocumentOfflineService({
    required this.repository, required this.remote, required this.files, required this.checksum,
  });

  Future<TechnicalDocument> download(TechnicalDocument document, {bool keepOffline=false}) async {
    final d=document.normalized();
    if(d.remotePath.isEmpty) throw StateError('Document has no remote path.');
    if(d.fileName.isEmpty) throw StateError('Document has no file name.');
    final bytes=await remote.download(d.remotePath);
    if(bytes.isEmpty) throw StateError('Downloaded document is empty.');
    final actual=checksum(bytes);
    if(d.checksum.isNotEmpty && actual.toLowerCase()!=d.checksum.toLowerCase()) {
      throw StateError('Downloaded document checksum does not match catalog.');
    }
    final path=await files.write(documentId:d.id,fileName:d.fileName,bytes:bytes);
    final now=DateTime.now().toUtc();
    final saved=TechnicalDocument(
      id:d.id,title:d.title,category:d.category,manufacturer:d.manufacturer,equipmentType:d.equipmentType,
      model:d.model,description:d.description,remotePath:d.remotePath,fileName:d.fileName,mimeType:d.mimeType,
      checksum:d.checksum.isEmpty?actual:d.checksum,sizeBytes:bytes.length,
      availability:TechnicalDocumentAvailability.downloaded,localPath:path,keepOffline:keepOffline,
      publishedAt:d.publishedAt,downloadedAt:now,updatedAt:d.updatedAt,
    );
    await repository.save(saved);
    return saved;
  }

  Future<TechnicalDocument> removeLocalCopy(TechnicalDocument document) async {
    final d=document.normalized();
    if(d.localPath!=null && d.localPath!.isNotEmpty && await files.exists(d.localPath!)) {
      await files.delete(d.localPath!);
    }
    final saved=TechnicalDocument(
      id:d.id,title:d.title,category:d.category,manufacturer:d.manufacturer,equipmentType:d.equipmentType,
      model:d.model,description:d.description,remotePath:d.remotePath,fileName:d.fileName,mimeType:d.mimeType,
      checksum:d.checksum,sizeBytes:d.sizeBytes,availability:TechnicalDocumentAvailability.remoteOnly,
      localPath:null,keepOffline:false,publishedAt:d.publishedAt,downloadedAt:null,updatedAt:d.updatedAt,
    );
    await repository.save(saved);
    return saved;
  }

  Future<bool> validateLocalCopy(TechnicalDocument document) async {
    final path=document.localPath;
    return document.availability==TechnicalDocumentAvailability.downloaded &&
      path!=null && path.isNotEmpty && await files.exists(path);
  }
}
