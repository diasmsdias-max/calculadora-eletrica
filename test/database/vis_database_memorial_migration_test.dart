import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('schema 8 to 9 adds memorial without losing materials', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute("""CREATE TABLE professional_projects (
      id TEXT PRIMARY KEY, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL,
      name TEXT NOT NULL, client TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '',
      responsible TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL)""");
    await db.execute("""CREATE TABLE professional_materials (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL,
      revision INTEGER NOT NULL, description TEXT NOT NULL, category TEXT NOT NULL DEFAULT '',
      unit TEXT NOT NULL DEFAULT '', quantity REAL, source TEXT NOT NULL DEFAULT '',
      notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE)""");
    const t = '2026-10-01T10:00:00Z';
    await db.insert('professional_projects', {'id':'p','contract_version':1,'revision':1,'name':'P',
      'client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_materials', {'id':'m','project_id':'p','contract_version':1,'revision':1,
      'description':'Cabo','category':'','unit':'m','quantity':null,'source':'','notes':'',
      'created_at':t,'updated_at':t});
    await VisDatabase.upgradeSchemaForTesting(db, 8, 9);
    expect(await db.query('professional_materials'), hasLength(1));
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='professional_memorials'");
    expect(tables, hasLength(1));
    await db.close();
  });
}
