import 'package:sqflite/sqflite.dart';
import 'technical_document.dart';
import 'technical_document_repository.dart';

class SqliteTechnicalDocumentRepository implements TechnicalDocumentRepository {
  final Database database;
  const SqliteTechnicalDocumentRepository(this.database);

  @override
  Future<List<TechnicalDocument>> list() async {
    final rows = await database.query('technical_documents', orderBy: 'manufacturer, model, title');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<TechnicalDocument?> getById(String id) async {
    final rows = await database.query('technical_documents', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> save(TechnicalDocument document) async {
    final d = document.normalized();
    if (d.id.isEmpty || d.title.isEmpty) {
      throw ArgumentError('Technical document id and title are required.');
    }
    await database.insert('technical_documents', _toRow(d), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String id) => database.delete('technical_documents', where: 'id = ?', whereArgs: [id]);

  Map<String, Object?> _toRow(TechnicalDocument d) => {
    'id': d.id, 'contract_version': TechnicalDocument.contractVersion, 'title': d.title,
    'category': d.category.name, 'manufacturer': d.manufacturer, 'equipment_type': d.equipmentType,
    'model': d.model, 'description': d.description, 'remote_path': d.remotePath,
    'file_name': d.fileName, 'mime_type': d.mimeType, 'checksum': d.checksum,
    'size_bytes': d.sizeBytes, 'availability': d.availability.name, 'local_path': d.localPath,
    'keep_offline': d.keepOffline ? 1 : 0, 'published_at': d.publishedAt?.toIso8601String(),
    'downloaded_at': d.downloadedAt?.toIso8601String(), 'updated_at': d.updatedAt?.toIso8601String(),
  };

  TechnicalDocument _fromRow(Map<String, Object?> r) => TechnicalDocument(
    id: r['id']! as String, title: r['title']! as String,
    category: TechnicalDocumentCategory.values.byName(r['category']! as String),
    manufacturer: r['manufacturer'] as String? ?? '', equipmentType: r['equipment_type'] as String? ?? '',
    model: r['model'] as String? ?? '', description: r['description'] as String? ?? '',
    remotePath: r['remote_path'] as String? ?? '', fileName: r['file_name'] as String? ?? '',
    mimeType: r['mime_type'] as String? ?? 'application/pdf', checksum: r['checksum'] as String? ?? '',
    sizeBytes: r['size_bytes'] as int?,
    availability: TechnicalDocumentAvailability.values.byName(r['availability'] as String? ?? 'remoteOnly'),
    localPath: r['local_path'] as String?, keepOffline: (r['keep_offline'] as int? ?? 0) == 1,
    publishedAt: _date(r['published_at']), downloadedAt: _date(r['downloaded_at']), updatedAt: _date(r['updated_at']),
  ).normalized();

  DateTime? _date(Object? value) => value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}
