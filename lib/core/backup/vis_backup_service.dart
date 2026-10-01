import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'vis_backup_envelope.dart';

/// Creates and restores the exportable V2 dataset.
///
/// Security-sensitive state is deliberately absent from [exportedTables].
/// Restore runs in one SQLite transaction, so a validation/database failure
/// rolls back the complete replacement.
class VisBackupService {
  static const exportedTables = <String>[
    'projects',
    'project_records',
    'loads',
    'circuits',
    'boards',
    'protections',
    'material_items',
    'professional_projects',
    'professional_loads',
    'professional_circuits',
    'professional_circuit_loads',
    'professional_boards',
    'professional_board_circuits',
    'professional_protections',
    'professional_sizing',
    'professional_materials',
    'professional_memorials',
  ];

  final Database database;

  const VisBackupService(this.database);

  Future<String> createBackup({
    required String appVersion,
    Map<String, dynamic>? professionalProfile,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
  }) async {
    final data = <String, dynamic>{};
    for (final table in exportedTables) {
      data[table] = await database.query(table);
    }

    final payload = <String, dynamic>{
      'database': data,
      if (professionalProfile != null)
        'professionalProfile': _jsonMap(professionalProfile),
      if (preferences != null) 'preferences': _jsonMap(preferences),
    };

    return VisBackupEnvelope.create(
      createdAt: createdAt ?? DateTime.now(),
      appVersion: appVersion,
      payload: payload,
    ).encode();
  }

  Future<VisBackupEnvelope> validate(String source) async {
    final envelope = VisBackupEnvelope.decode(source);
    _validatedDatabase(envelope.payload);
    return envelope;
  }

  Future<VisBackupEnvelope> restore(String source) async {
    final envelope = VisBackupEnvelope.decode(source);
    final backup = _validatedDatabase(envelope.payload);

    await database.transaction((txn) async {
      for (final table in exportedTables.reversed) {
        await txn.delete(table);
      }

      for (final table in exportedTables) {
        for (final row in backup[table]!) {
          await txn.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }

      for (final table in exportedTables) {
        final expected = backup[table]!.length;
        final actual = Sqflite.firstIntValue(
              await txn.rawQuery('SELECT COUNT(*) FROM $table'),
            ) ??
            0;
        if (actual != expected) {
          throw StateError('Falha ao validar restauração da tabela $table.');
        }
      }
    });

    return envelope;
  }

  static Map<String, List<Map<String, Object?>>> _validatedDatabase(
    Map<String, dynamic> payload,
  ) {
    final rawDatabase = payload['database'];
    if (rawDatabase is! Map) {
      throw const FormatException('Banco de dados ausente no backup.');
    }
    final database = Map<String, dynamic>.from(rawDatabase);
    final result = <String, List<Map<String, Object?>>>{};

    for (final table in exportedTables) {
      var rows = database[table];
      // Backups created before the Professional graph was introduced may
      // omit any professional_* table. Treat it as empty for compatibility.
      if (rows == null && table.startsWith('professional_')) {
        rows = const <Object?>[];
      }
      if (rows is! List) {
        throw FormatException('Tabela $table ausente ou inválida no backup.');
      }
      result[table] = rows.map<Map<String, Object?>>((raw) {
        if (raw is! Map) {
          throw FormatException('Registro inválido na tabela $table.');
        }
        final normalized = jsonDecode(jsonEncode(raw));
        if (normalized is! Map) {
          throw FormatException('Registro inválido na tabela $table.');
        }
        return Map<String, Object?>.from(normalized);
      }).toList(growable: false);
    }

    _validateReferences(result);
    return result;
  }

  static void _validateReferences(
    Map<String, List<Map<String, Object?>>> data,
  ) {
    final projectIds = _ids(data['projects']!);
    final circuitIds = _ids(data['circuits']!);
    final boardIds = _ids(data['boards']!);

    for (final table in [
      'project_records',
      'loads',
      'circuits',
      'boards',
      'protections',
      'material_items',
    ]) {
      for (final row in data[table]!) {
        _requireReference(row, 'project_id', projectIds, table);
      }
    }

    for (final row in data['loads']!) {
      _optionalReference(row, 'circuit_id', circuitIds, 'loads');
    }
    for (final row in data['circuits']!) {
      _optionalReference(row, 'board_id', boardIds, 'circuits');
    }
    for (final row in data['protections']!) {
      _optionalReference(row, 'circuit_id', circuitIds, 'protections');
      _optionalReference(row, 'board_id', boardIds, 'protections');
    }

    final professionalProjectIds = _ids(data['professional_projects']!);
    final professionalLoadIds = _ids(data['professional_loads']!);
    final professionalCircuitIds = _ids(data['professional_circuits']!);
    final professionalBoardIds = _ids(data['professional_boards']!);

    for (final table in [
      'professional_loads',
      'professional_circuits',
      'professional_boards',
      'professional_protections',
      'professional_sizing',
      'professional_materials',
      'professional_memorials',
    ]) {
      for (final row in data[table]!) {
        _requireReference(row, 'project_id', professionalProjectIds, table);
      }
    }

    for (final row in data['professional_circuit_loads']!) {
      _requireReference(row, 'circuit_id', professionalCircuitIds, 'professional_circuit_loads');
      _requireReference(row, 'load_id', professionalLoadIds, 'professional_circuit_loads');
    }
    for (final row in data['professional_board_circuits']!) {
      _requireReference(row, 'board_id', professionalBoardIds, 'professional_board_circuits');
      _requireReference(row, 'circuit_id', professionalCircuitIds, 'professional_board_circuits');
    }
    for (final row in data['professional_protections']!) {
      _requireReference(row, 'circuit_id', professionalCircuitIds, 'professional_protections');
    }
    for (final row in data['professional_sizing']!) {
      _requireReference(row, 'circuit_id', professionalCircuitIds, 'professional_sizing');
    }
  }

  static Set<String> _ids(List<Map<String, Object?>> rows) {
    final result = <String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id is! String || id.isEmpty || !result.add(id)) {
        throw const FormatException('Identificador ausente ou duplicado no backup.');
      }
    }
    return result;
  }

  static void _requireReference(
    Map<String, Object?> row,
    String key,
    Set<String> validIds,
    String table,
  ) {
    final value = row[key];
    if (value is! String || value.isEmpty || !validIds.contains(value)) {
      throw FormatException('Referência inválida em $table.$key.');
    }
  }

  static void _optionalReference(
    Map<String, Object?> row,
    String key,
    Set<String> validIds,
    String table,
  ) {
    final value = row[key];
    if (value == null) return;
    if (value is! String || value.isEmpty || !validIds.contains(value)) {
      throw FormatException('Referência inválida em $table.$key.');
    }
  }

  static Map<String, dynamic> _jsonMap(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(value)) as Map,
      );
}
