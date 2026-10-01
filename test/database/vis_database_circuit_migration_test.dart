import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('schema 3 to 4 adds professional circuits without losing data', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'));
    await db.execute('''CREATE TABLE professional_projects (
      id TEXT PRIMARY KEY, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL,
      name TEXT NOT NULL, client TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '',
      responsible TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE professional_loads (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL,
      revision INTEGER NOT NULL, name TEXT NOT NULL, category TEXT NOT NULL DEFAULT '',
      quantity INTEGER NOT NULL DEFAULT 1, power_w REAL NOT NULL DEFAULT 0,
      voltage_v REAL NOT NULL DEFAULT 0, power_factor REAL, notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE)''');
    await db.insert('professional_projects', {
      'id':'p','contract_version':1,'revision':2,'name':'Existente','client':'',
      'address':'','responsible':'','notes':'','created_at':'2026-10-01T10:00:00Z',
      'updated_at':'2026-10-01T11:00:00Z'});
    await db.insert('professional_loads', {
      'id':'l','project_id':'p','contract_version':1,'revision':1,'name':'Carga',
      'category':'','quantity':1,'power_w':100.0,'voltage_v':127.0,'power_factor':null,
      'notes':'','created_at':'2026-10-01T10:00:00Z','updated_at':'2026-10-01T10:00:00Z'});

    await VisDatabase.upgradeSchemaForTesting(db, 3, 4);

    expect(await db.query('professional_projects'), hasLength(1));
    expect(await db.query('professional_loads'), hasLength(1));
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('professional_circuits','professional_circuit_loads')");
    expect(tables, hasLength(2));
    await db.close();
  });
}
