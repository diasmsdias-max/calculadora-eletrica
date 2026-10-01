import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/database/vis_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('schema 2 to 3 preserves professional projects and adds loads', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE professional_projects (
        id TEXT PRIMARY KEY,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        name TEXT NOT NULL,
        client TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        responsible TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.insert('professional_projects', {
      'id': 'existing-project',
      'contract_version': 1,
      'revision': 4,
      'name': 'Projeto existente',
      'client': 'Cliente',
      'address': '',
      'responsible': '',
      'notes': '',
      'created_at': '2026-10-01T10:00:00.000Z',
      'updated_at': '2026-10-01T11:00:00.000Z',
    });

    await VisDatabase.upgradeSchemaForTesting(db, 2, 3);

    final projects = await db.query('professional_projects');
    expect(projects, hasLength(1));
    expect(projects.single['id'], 'existing-project');
    expect(projects.single['revision'], 4);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='professional_loads'",
    );
    expect(tables, hasLength(1));

    await db.insert('professional_loads', {
      'id': 'load-01',
      'project_id': 'existing-project',
      'contract_version': 1,
      'revision': 1,
      'name': 'Motor',
      'category': '',
      'quantity': 1,
      'power_w': 1500.0,
      'voltage_v': 220.0,
      'power_factor': null,
      'notes': '',
      'created_at': '2026-10-01T12:00:00.000Z',
      'updated_at': '2026-10-01T12:00:00.000Z',
    });
    expect(await db.query('professional_loads'), hasLength(1));

    await db.close();
  });
}
