import 'package:sqflite/sqflite.dart';

import 'professional_circuit.dart';
import 'professional_circuit_repository.dart';

class SqliteProfessionalCircuitRepository implements ProfessionalCircuitRepository {
  final Database database;
  const SqliteProfessionalCircuitRepository(this.database);

  @override
  Future<List<ProfessionalCircuit>> getByProject(String projectId) async {
    final rows = await database.query('professional_circuits',
        where: 'project_id = ?', whereArgs: [projectId], orderBy: 'name COLLATE NOCASE');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<ProfessionalCircuit?> getById(String id) async {
    final rows = await database.query('professional_circuits',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> save(ProfessionalCircuit circuit) async {
    final value = circuit.normalized();
    if (value.id.isEmpty || value.projectId.isEmpty || value.name.isEmpty) {
      throw ArgumentError('Circuit id, project id and name are required.');
    }
    if (value.voltageV != null && value.voltageV! <= 0) {
      throw ArgumentError('Circuit voltage must be positive when informed.');
    }
    if (value.phases != null && (value.phases! < 1 || value.phases! > 3)) {
      throw ArgumentError('Circuit phases must be between 1 and 3.');
    }
    final row = _toRow(value);
    final updated = await database.update('professional_circuits', row,
        where: 'id = ?', whereArgs: [value.id]);
    if (updated == 0) await database.insert('professional_circuits', row);
  }

  @override
  Future<void> delete(String id) =>
      database.delete('professional_circuits', where: 'id = ?', whereArgs: [id]);

  @override
  Future<List<String>> getLoadIds(String circuitId) async {
    final rows = await database.query('professional_circuit_loads',
        columns: ['load_id'], where: 'circuit_id = ?', whereArgs: [circuitId]);
    return rows.map((row) => row['load_id']! as String).toList(growable: false);
  }

  @override
  Future<void> replaceLoads(String circuitId, Iterable<String> loadIds) async {
    await database.transaction((txn) async {
      await txn.delete('professional_circuit_loads',
          where: 'circuit_id = ?', whereArgs: [circuitId]);
      for (final loadId in loadIds.toSet()) {
        await txn.insert('professional_circuit_loads',
            {'circuit_id': circuitId, 'load_id': loadId});
      }
    });
  }

  Map<String, Object?> _toRow(ProfessionalCircuit c) => {
        'id': c.id,
        'project_id': c.projectId,
        'contract_version': ProfessionalCircuit.contractVersion,
        'revision': c.revision,
        'name': c.name,
        'description': c.description,
        'voltage_v': c.voltageV,
        'phases': c.phases,
        'notes': c.notes,
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
      };

  ProfessionalCircuit _fromRow(Map<String, Object?> row) => ProfessionalCircuit(
        id: row['id']! as String,
        projectId: row['project_id']! as String,
        revision: row['revision']! as int,
        name: row['name']! as String,
        description: row['description'] as String? ?? '',
        voltageV: (row['voltage_v'] as num?)?.toDouble(),
        phases: row['phases'] as int?,
        notes: row['notes'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      ).normalized();
}
