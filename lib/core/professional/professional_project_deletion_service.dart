import 'package:sqflite/sqflite.dart';

class ProfessionalProjectDeletionService {
  final Database database;

  const ProfessionalProjectDeletionService(this.database);

  Future<bool> deleteProject(String projectId) async {
    if (projectId.trim().isEmpty) {
      throw ArgumentError.value(projectId, 'projectId', 'Project id is required.');
    }

    return database.transaction((txn) async {
      final deleted = await txn.delete(
        'professional_projects',
        where: 'id = ?',
        whereArgs: [projectId],
      );
      if (deleted == 0) return false;

      for (final table in _projectTables) {
        final rows = await txn.query(
          table,
          columns: const ['id'],
          where: 'project_id = ?',
          whereArgs: [projectId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          throw StateError('Project deletion left dependent rows in $table.');
        }
      }
      return true;
    });
  }

  static const _projectTables = <String>[
    'professional_loads',
    'professional_circuits',
    'professional_boards',
    'professional_protections',
    'professional_sizing',
    'professional_materials',
    'professional_memorials',
  ];
}
