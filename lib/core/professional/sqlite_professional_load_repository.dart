import 'package:sqflite/sqflite.dart';

import 'professional_load.dart';
import 'professional_load_repository.dart';

class SqliteProfessionalLoadRepository implements ProfessionalLoadRepository {
  final Database database;
  const SqliteProfessionalLoadRepository(this.database);

  @override
  Future<List<ProfessionalLoad>> getByProject(String projectId) async {
    final rows = await database.query(
      'professional_loads',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<ProfessionalLoad?> getById(String id) async {
    final rows = await database.query(
      'professional_loads',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> save(ProfessionalLoad load) async {
    final value = load.normalized();
    if (value.id.isEmpty || value.projectId.isEmpty || value.name.isEmpty) {
      throw ArgumentError('Load id, project id and name are required.');
    }
    final row = _toRow(value);
    final updated = await database.update(
      'professional_loads',
      row,
      where: 'id = ?',
      whereArgs: [value.id],
    );
    if (updated == 0) {
      await database.insert('professional_loads', row);
    }
  }

  @override
  Future<void> delete(String id) =>
      database.delete('professional_loads', where: 'id = ?', whereArgs: [id]);

  Map<String, Object?> _toRow(ProfessionalLoad load) => {
        'id': load.id,
        'project_id': load.projectId,
        'contract_version': ProfessionalLoad.contractVersion,
        'revision': load.revision,
        'name': load.name,
        'category': load.category,
        'quantity': load.quantity,
        'power_w': load.powerW,
        'voltage_v': load.voltageV,
        'power_factor': load.powerFactor,
        'simultaneity_factor': load.simultaneityFactor,
        'simultaneity_source': load.simultaneitySource,
        'simultaneity_basis': load.simultaneityBasis,
        'notes': load.notes,
        'created_at': load.createdAt.toIso8601String(),
        'updated_at': load.updatedAt.toIso8601String(),
      };

  ProfessionalLoad _fromRow(Map<String, Object?> row) => ProfessionalLoad(
        id: row['id']! as String,
        projectId: row['project_id']! as String,
        revision: row['revision']! as int,
        name: row['name']! as String,
        category: row['category'] as String? ?? '',
        quantity: row['quantity']! as int,
        powerW: (row['power_w']! as num).toDouble(),
        voltageV: (row['voltage_v']! as num).toDouble(),
        powerFactor: (row['power_factor'] as num?)?.toDouble(),
        simultaneityFactor: (row['simultaneity_factor'] as num?)?.toDouble(),
        simultaneitySource: row['simultaneity_source'] as String?,
        simultaneityBasis: row['simultaneity_basis'] as String? ?? '',
        notes: row['notes'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      ).normalized();
}
