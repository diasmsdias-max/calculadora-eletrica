import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_project.dart';
import 'project_record.dart';
import 'project_record_repository.dart';
import 'project_repository.dart';

class SqliteProjectRepository implements ProjectRepository {
  final Database database;

  const SqliteProjectRepository(this.database);

  @override
  Future<List<LocalProject>> getAll() async {
    final rows = await database.query('projects', orderBy: 'updated_at DESC');
    return rows.map(_projectFromRow).toList();
  }

  @override
  Future<void> save(LocalProject project) {
    return database.insert(
      'projects',
      _projectToRow(project),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}

class SqliteProjectRecordRepository implements ProjectRecordRepository {
  final Database database;

  const SqliteProjectRecordRepository(this.database);

  @override
  Future<List<ProjectRecord>> getByProject(String projectId) async {
    final rows = await database.query(
      'project_records',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_recordFromRow).toList();
  }

  @override
  Future<void> save(ProjectRecord record) {
    return database.insert(
      'project_records',
      _recordToRow(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('project_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteByProject(String projectId) async {
    await database.delete(
      'project_records',
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
  }
}

Map<String, Object?> _projectToRow(LocalProject project) => {
  'id': project.id,
  'name': project.name,
  'client': project.client,
  'address': project.address,
  'responsible': project.responsible,
  'notes': project.notes,
  'created_at': project.createdAt.toIso8601String(),
  'updated_at': project.updatedAt.toIso8601String(),
};

LocalProject _projectFromRow(Map<String, Object?> row) => LocalProject(
  id: row['id']! as String,
  name: row['name']! as String,
  client: row['client'] as String? ?? '',
  address: row['address'] as String? ?? '',
  responsible: row['responsible'] as String? ?? '',
  notes: row['notes'] as String? ?? '',
  createdAt: DateTime.parse(row['created_at']! as String),
  updatedAt: DateTime.parse(row['updated_at']! as String),
);

Map<String, Object?> _recordToRow(ProjectRecord record) => {
  'id': record.id,
  'project_id': record.projectId,
  'type': record.type.name,
  'title': record.title,
  'summary': record.summary,
  'data_json': jsonEncode(record.data),
  'created_at': record.createdAt.toIso8601String(),
};

ProjectRecord _recordFromRow(Map<String, Object?> row) => ProjectRecord(
  id: row['id']! as String,
  projectId: row['project_id']! as String,
  type: ProjectRecordType.values.byName(row['type']! as String),
  title: row['title']! as String,
  summary: row['summary'] as String? ?? '',
  data: Map<String, dynamic>.from(
    jsonDecode(row['data_json']! as String) as Map,
  ),
  createdAt: DateTime.parse(row['created_at']! as String),
);
