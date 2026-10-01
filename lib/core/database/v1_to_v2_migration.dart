import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_project.dart';
import 'project_record.dart';
import 'project_record_repository.dart';
import 'project_repository.dart';

/// Copies legacy V1 data into V2 without deleting the legacy source.
class V1ToV2Migration {
  static const migrationKey = 'migration_v1_to_v2';
  static const migrationVersion = '1';

  final Database database;
  final ProjectRepository legacyProjects;
  final ProjectRecordRepository legacyRecords;

  const V1ToV2Migration({
    required this.database,
    required this.legacyProjects,
    required this.legacyRecords,
  });

  Future<bool> isCompleted() async {
    final rows = await database.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [migrationKey],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == migrationVersion;
  }

  Future<bool> migrateIfNeeded() async {
    if (await isCompleted()) return false;

    final projects = await legacyProjects.getAll();
    final records = <ProjectRecord>[];
    for (final project in projects) {
      records.addAll(await legacyRecords.getByProject(project.id));
    }

    await database.transaction((txn) async {
      for (final project in projects) {
        await txn.insert(
          'projects',
          _projectRow(project),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final record in records) {
        await txn.insert(
          'project_records',
          _recordRow(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (projects.isNotEmpty) {
        final count = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM projects WHERE id IN '
            '(${_placeholders(projects.length)})',
            projects.map((p) => p.id).toList(),
          ),
        ) ?? 0;
        if (count != projects.length) {
          throw StateError('V1 project migration validation failed');
        }
      }

      if (records.isNotEmpty) {
        final count = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM project_records WHERE id IN '
            '(${_placeholders(records.length)})',
            records.map((r) => r.id).toList(),
          ),
        ) ?? 0;
        if (count != records.length) {
          throw StateError('V1 record migration validation failed');
        }
      }

      await txn.insert(
        'app_metadata',
        {'key': migrationKey, 'value': migrationVersion},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return true;
  }

  static String _placeholders(int count) =>
      List.filled(count, '?').join(',');

  static Map<String, Object?> _projectRow(LocalProject project) => {
    'id': project.id,
    'name': project.name,
    'client': project.client,
    'address': project.address,
    'responsible': project.responsible,
    'notes': project.notes,
    'created_at': project.createdAt.toIso8601String(),
    'updated_at': project.updatedAt.toIso8601String(),
  };

  static Map<String, Object?> _recordRow(ProjectRecord record) => {
    'id': record.id,
    'project_id': record.projectId,
    'type': record.type.name,
    'title': record.title,
    'summary': record.summary,
    'data_json': jsonEncode(record.data),
    'created_at': record.createdAt.toIso8601String(),
  };
}
