import 'dart:io';

import 'package:path/path.dart' as p;

import 'technical_document_offline_service.dart';

class LocalTechnicalDocumentFileStore implements TechnicalDocumentFileStore {
  final Directory baseDirectory;

  const LocalTechnicalDocumentFileStore(this.baseDirectory);

  @override
  Future<String> write({
    required String documentId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final safeDocumentId = _safeSegment(documentId);
    final safeFileName = _safeFileName(fileName);
    final directory = Directory(
      p.join(baseDirectory.path, 'technical_documents', safeDocumentId),
    );
    await directory.create(recursive: true);

    final file = File(p.join(directory.path, safeFileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<bool> exists(String localPath) => File(localPath).exists();

  @override
  Future<void> delete(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }

    final parent = file.parent;
    if (await parent.exists() && await parent.list().isEmpty) {
      await parent.delete();
    }
  }

  String _safeSegment(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      throw ArgumentError.value(value, 'documentId', 'Invalid document id.');
    }
    return sanitized;
  }

  String _safeFileName(String value) {
    final name = p.basename(value.trim());
    final sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (sanitized.isEmpty || sanitized == '.' || sanitized == '..') {
      throw ArgumentError.value(value, 'fileName', 'Invalid file name.');
    }
    return sanitized;
  }
}
