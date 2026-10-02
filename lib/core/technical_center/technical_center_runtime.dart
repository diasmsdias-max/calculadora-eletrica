import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'http_technical_document_source.dart';
import 'local_technical_document_file_store.dart';
import 'technical_center_actions.dart';
import 'technical_document.dart';
import 'technical_document_catalog_sync_service.dart';
import 'technical_document_checksum.dart';
import 'technical_document_offline_service.dart';
import 'technical_document_repository.dart';

class TechnicalCenterRuntime implements TechnicalCenterActions {
  final TechnicalDocumentCatalogSyncService catalog;
  final TechnicalDocumentOfflineService offline;

  const TechnicalCenterRuntime({
    required this.catalog,
    required this.offline,
  });

  static Future<TechnicalCenterRuntime> create({
    required TechnicalDocumentRepository repository,
    required Uri baseUri,
  }) async {
    final databaseRoot = await getDatabasesPath();
    final fileStore = LocalTechnicalDocumentFileStore(
      Directory(p.join(databaseRoot, 'technical_center')),
    );
    final source = HttpTechnicalDocumentSource(baseUri: baseUri);
    return TechnicalCenterRuntime(
      catalog: TechnicalDocumentCatalogSyncService(
        repository: repository,
        source: source,
      ),
      offline: TechnicalDocumentOfflineService(
        repository: repository,
        remote: source,
        files: fileStore,
        checksum: technicalDocumentSha256,
      ),
    );
  }

  @override
  Future<void> syncCatalog() async {
    await catalog.sync();
  }

  @override
  Future<TechnicalDocument> download(
    TechnicalDocument document, {
    bool keepOffline = false,
  }) => offline.download(document, keepOffline: keepOffline);

  @override
  Future<TechnicalDocument> removeLocalCopy(TechnicalDocument document) =>
      offline.removeLocalCopy(document);
}
