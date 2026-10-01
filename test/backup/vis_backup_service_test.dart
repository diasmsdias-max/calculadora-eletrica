import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/backup/vis_backup_envelope.dart';
import 'package:calculadora_eletrica/core/backup/vis_backup_service.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await VisDatabase.createSchemaForTesting(db);
  });

  tearDown(() => db.close());

  test('backup exports technical data but not local metadata or secrets', () async {
    await db.insert('projects', _project('p1', 'Projeto original'));
    await db.insert('app_metadata', {'key': 'license_token', 'value': 'SECRET'});

    final source = await VisBackupService(db).createBackup(
      appVersion: '2.0.0-test',
      professionalProfile: {'companyName': 'Boecker'},
      createdAt: DateTime.utc(2026, 10, 1),
    );

    expect(source, contains('Projeto original'));
    expect(source, contains('Boecker'));
    expect(source, isNot(contains('SECRET')));
    expect(source, isNot(contains('license_token')));
  });

  test('invalid backup is rejected without changing local data', () async {
    await db.insert('projects', _project('local', 'Projeto local'));

    expect(
      () => VisBackupService(db).restore('{"invalid":true}'),
      throwsA(isA<FormatException>()),
    );

    final rows = await db.query('projects');
    expect(rows, hasLength(1));
    expect(rows.single['name'], 'Projeto local');
  });

  test('restore replaces exportable data and preserves local metadata', () async {
    final service = VisBackupService(db);
    await db.insert('projects', _project('backup', 'Projeto do backup'));
    final source = await service.createBackup(appVersion: '2.0.0-test');

    await db.delete('projects');
    await db.insert('projects', _project('local', 'Projeto local'));
    await db.insert('app_metadata', {'key': 'license_state', 'value': 'ACTIVE'});

    await service.restore(source);

    final projects = await db.query('projects');
    expect(projects, hasLength(1));
    expect(projects.single['id'], 'backup');

    final metadata = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['license_state'],
    );
    expect(metadata.single['value'], 'ACTIVE');
  });

  test('database failure rolls restore back atomically', () async {
    final service = VisBackupService(db);
    await db.insert('projects', _project('local', 'Projeto local'));

    final emptyDatabase = <String, dynamic>{
      for (final table in VisBackupService.exportedTables) table: <dynamic>[],
    };
    emptyDatabase['project_records'] = [
      {
        'id': 'r1',
        'project_id': 'missing',
        'type': 'motor',
        'title': 'Inválido',
        'summary': '',
        'data_json': '{}',
        'created_at': DateTime.utc(2026, 10, 1).toIso8601String(),
      }
    ];
    final badSource = VisBackupEnvelope.create(
      createdAt: DateTime.utc(2026, 10, 1),
      appVersion: '2.0.0-test',
      payload: {'database': emptyDatabase},
    ).encode();

    expect(() => service.restore(badSource), throwsA(anything));

    final projects = await db.query('projects');
    expect(projects, hasLength(1));
    expect(projects.single['id'], 'local');
  });
}

Map<String, Object?> _project(String id, String name) => {
      'id': id,
      'name': name,
      'client': '',
      'address': '',
      'responsible': '',
      'notes': '',
      'created_at': DateTime.utc(2026, 10, 1).toIso8601String(),
      'updated_at': DateTime.utc(2026, 10, 1).toIso8601String(),
    };
