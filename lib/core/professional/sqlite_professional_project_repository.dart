import 'package:sqflite/sqflite.dart';

import 'professional_project.dart';
import 'professional_project_repository.dart';

class SqliteProfessionalProjectRepository
    implements ProfessionalProjectRepository {
  final Database database;

  const SqliteProfessionalProjectRepository(this.database);

  @override
  Future<List<ProfessionalProject>> getAll() async {
    final rows = await database.query(
      'professional_projects',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ProfessionalProject?> getById(String id) async {
    final rows = await database.query(
      'professional_projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> save(ProfessionalProject project) async {
    final normalized = project.normalized();
    if (normalized.id.isEmpty || normalized.name.isEmpty) {
      throw ArgumentError('Professional project id and name are required.');
    }
    final row = _toRow(normalized);
    final updated = await database.update(
      'professional_projects',
      row,
      where: 'id = ?',
      whereArgs: [normalized.id],
    );
    if (updated == 0) {
      await database.insert(
        'professional_projects',
        row,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  @override
  Future<void> delete(String id) =>
      database.delete('professional_projects', where: 'id = ?', whereArgs: [id]);

  Map<String, Object?> _toRow(ProfessionalProject project) => {
        'id': project.id,
        'contract_version': ProfessionalProject.contractVersion,
        'revision': project.revision,
        'name': project.name,
        'client': project.client,
        'address': project.address,
        'responsible': project.responsible,
        'notes': project.notes,
        'created_at': project.createdAt.toUtc().toIso8601String(),
        'updated_at': project.updatedAt.toUtc().toIso8601String(),
      };

  ProfessionalProject _fromRow(Map<String, Object?> row) {
    final contractVersion = row['contract_version'] as int;
    if (contractVersion != ProfessionalProject.contractVersion) {
      throw FormatException(
        'Unsupported professional project contract: $contractVersion',
      );
    }
    return ProfessionalProject(
      id: row['id']! as String,
      revision: row['revision']! as int,
      name: row['name']! as String,
      client: row['client'] as String? ?? '',
      address: row['address'] as String? ?? '',
      responsible: row['responsible'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    ).normalized();
  }
}
