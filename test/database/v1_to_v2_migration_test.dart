import 'package:calculadora_eletrica/core/database/local_project.dart';
import 'package:calculadora_eletrica/core/database/project_record.dart';
import 'package:calculadora_eletrica/core/database/project_record_repository.dart';
import 'package:calculadora_eletrica/core/database/project_repository.dart';
import 'package:calculadora_eletrica/core/database/v1_to_v2_migration.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await VisDatabase.createSchemaForTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('copies V1 projects and records and marks migration complete', () async {
    final projects = PreferencesProjectRepository();
    final records = PreferencesProjectRecordRepository();
    final project = LocalProject(
      id: 'p1',
      name: 'Obra existente',
      client: 'Cliente',
      address: 'Endereço',
      responsible: 'Responsável',
      notes: 'Preservar',
      createdAt: DateTime.utc(2026, 9, 30),
      updatedAt: DateTime.utc(2026, 10, 1),
    );
    final record = ProjectRecord(
      id: 'r1',
      projectId: 'p1',
      type: ProjectRecordType.voltageDrop,
      title: 'Queda de tensão',
      summary: '2,1%',
      data: {'voltageDropPercent': 2.1, 'cableMm2': 10.0},
      createdAt: DateTime.utc(2026, 10, 1),
    );
    await projects.save(project);
    await records.save(record);

    final migration = V1ToV2Migration(
      database: db,
      legacyProjects: projects,
      legacyRecords: records,
    );

    expect(await migration.migrateIfNeeded(), isTrue);
    expect(await migration.isCompleted(), isTrue);

    final migratedProjects = await db.query('projects');
    final migratedRecords = await db.query('project_records');
    expect(migratedProjects.single['id'], 'p1');
    expect(migratedProjects.single['name'], 'Obra existente');
    expect(migratedRecords.single['id'], 'r1');
    expect(migratedRecords.single['project_id'], 'p1');

    // The source remains available after a successful copy.
    expect((await projects.getAll()).single.id, 'p1');
    expect((await records.getByProject('p1')).single.id, 'r1');
  });

  test('second execution is idempotent', () async {
    final projects = PreferencesProjectRepository();
    final records = PreferencesProjectRecordRepository();
    await projects.save(LocalProject(
      id: 'p1',
      name: 'Projeto',
      client: '',
      address: '',
      responsible: '',
      notes: '',
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
    ));

    final migration = V1ToV2Migration(
      database: db,
      legacyProjects: projects,
      legacyRecords: records,
    );

    expect(await migration.migrateIfNeeded(), isTrue);
    expect(await migration.migrateIfNeeded(), isFalse);
    expect(
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM projects')),
      1,
    );
  });

  test('empty V1 storage still completes safely', () async {
    final migration = V1ToV2Migration(
      database: db,
      legacyProjects: PreferencesProjectRepository(),
      legacyRecords: PreferencesProjectRecordRepository(),
    );

    expect(await migration.migrateIfNeeded(), isTrue);
    expect(await migration.isCompleted(), isTrue);
    expect(await db.query('projects'), isEmpty);
    expect(await db.query('project_records'), isEmpty);
  });
}
