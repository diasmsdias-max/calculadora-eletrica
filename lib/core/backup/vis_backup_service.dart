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
    // Decode and validate everything before opening the write transaction.
    final envelope = VisBackupEnvelope.decode(source);
    final backup = _validatedDatabase(envelope.payload);

    await database.transaction((txn) async {
      // Delete children before parents. Metadata, licensing and other local
      // state are intentionally not touched.
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

      // Validate row counts while still inside the transaction. Any mismatch
      // throws and sqflite rolls the whole replacement back.
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
      final rows = database[table];
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

    return result;
  }

  static Map<String, dynamic> _jsonMap(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(value)) as Map,
      );
}
