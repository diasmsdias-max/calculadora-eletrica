import 'package:calculadora_eletrica/core/database/local_project.dart';
import 'package:calculadora_eletrica/core/database/project_record.dart';
import 'package:calculadora_eletrica/core/database/sqlite_project_repositories.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqliteProjectRepository projects;
  late SqliteProjectRecordRepository records;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    projects = SqliteProjectRepository(db);
    records = SqliteProjectRecordRepository(db);
  });

  tearDown(() async => db.close());

  test('updating a project preserves its child records', () async {
    final createdAt = DateTime.utc(2026, 10, 1);
    final project = LocalProject(
      id: 'p1',
      name: 'Projeto original',
      client: 'Cliente',
      address: '',
      responsible: '',
      notes: '',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    await projects.save(project);
    await records.save(ProjectRecord(
      id: 'r1',
      projectId: project.id,
      type: ProjectRecordType.motor,
      title: 'Motor',
      summary: '15 CV',
      data: const {'powerCv': 15},
      createdAt: createdAt,
    ));

    await projects.save(project.copyWith(
      name: 'Projeto editado',
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    ));

    final savedProjects = await projects.getAll();
    final savedRecords = await records.getByProject(project.id);
    expect(savedProjects.single.name, 'Projeto editado');
    expect(savedRecords.single.id, 'r1');
  });
}
