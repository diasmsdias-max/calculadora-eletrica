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

  test('backup includes professional projects', () async {
    await db.insert('professional_projects', {
      'id': 'pro-1',
      'contract_version': 1,
      'revision': 1,
      'name': 'Projeto Profissional',
      'client': '',
      'address': '',
      'responsible': '',
      'notes': '',
      'created_at': DateTime.utc(2026, 10, 1).toIso8601String(),
      'updated_at': DateTime.utc(2026, 10, 1).toIso8601String(),
    });

    final service = VisBackupService(db);
    final source = await service.createBackup(appVersion: '2.0.0-test');
    await db.delete('professional_projects');

    await service.restore(source);

    final rows = await db.query('professional_projects');
    expect(rows, hasLength(1));
    expect(rows.single['id'], 'pro-1');
  });

  test('backup restores complete professional graph with relations', () async {
    final t = DateTime.utc(2026, 10, 1).toIso8601String();
    await db.execute('PRAGMA foreign_keys = ON');
    await db.insert('professional_projects', {'id':'p','contract_version':1,'revision':1,'name':'P','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_loads', {'id':'l','project_id':'p','contract_version':1,'revision':1,'name':'Motor','category':'','quantity':1,'power_w':1000.0,'voltage_v':220.0,'power_factor':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuits', {'id':'c','project_id':'p','contract_version':1,'revision':1,'name':'C1','description':'','voltage_v':null,'phases':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuit_loads', {'circuit_id':'c','load_id':'l'});
    await db.insert('professional_boards', {'id':'b','project_id':'p','contract_version':1,'revision':1,'name':'QD1','description':'','location':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_board_circuits', {'board_id':'b','circuit_id':'c'});
    await db.insert('professional_protections', {'id':'pr','project_id':'p','circuit_id':'c','contract_version':1,'revision':1,'name':'Disjuntor','device_type':'','rated_current_a':null,'poles':null,'trip_curve':'','breaking_capacity_ka':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_sizing', {'id':'s','project_id':'p','circuit_id':'c','contract_version':1,'revision':1,'design_current_a':null,'conductor_section_mm2':null,'voltage_drop_percent':null,'protection_current_a':null,'method':'','criteria':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_materials', {'id':'mat','project_id':'p','contract_version':1,'revision':1,'description':'Cabo','category':'','unit':'m','quantity':null,'source':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_memorials', {'id':'mem','project_id':'p','contract_version':1,'revision':1,'title':'Memorial','scope':'','criteria':'','conclusions':'','notes':'','created_at':t,'updated_at':t});

    final service = VisBackupService(db);
    final source = await service.createBackup(appVersion: '2.0.0-test');
    await db.delete('professional_projects');
    expect(await db.query('professional_loads'), isEmpty);
    await service.restore(source);

    for (final table in ['professional_projects','professional_loads','professional_circuits','professional_circuit_loads',
      'professional_boards','professional_board_circuits','professional_protections','professional_sizing',
      'professional_materials','professional_memorials']) {
      expect(await db.query(table), hasLength(1), reason: table);
    }
    expect((await db.query('professional_circuit_loads')).single['load_id'], 'l');
    expect((await db.query('professional_board_circuits')).single['circuit_id'], 'c');
  });

  test('EP20 backup without professional tables remains restorable', () async {
    final database = <String, dynamic>{
      for (final table in VisBackupService.exportedTables)
        if (!table.startsWith('professional_')) table: <dynamic>[],
    };
    final source = VisBackupEnvelope.create(
      createdAt: DateTime.utc(2026, 10, 1),
      appVersion: '1.0.0',
      payload: {'database': database},
    ).encode();

    await VisBackupService(db).restore(source);

    expect(await db.query('professional_projects'), isEmpty);
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

    await expectLater(service.restore(badSource), throwsA(isA<FormatException>()));

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
