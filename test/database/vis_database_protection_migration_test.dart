import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('schema 5 to 6 adds protections without losing existing data', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('''CREATE TABLE professional_projects (
      id TEXT PRIMARY KEY, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL,
      name TEXT NOT NULL, client TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '',
      responsible TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE professional_circuits (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL,
      revision INTEGER NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '',
      voltage_v REAL, phases INTEGER, notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE professional_boards (
      id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL,
      revision INTEGER NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '',
      location TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
      FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE)''');
    await db.insert('professional_projects',{'id':'p','contract_version':1,'revision':3,
      'name':'Existente','client':'','address':'','responsible':'','notes':'',
      'created_at':'2026-10-01T10:00:00Z','updated_at':'2026-10-01T11:00:00Z'});
    await db.insert('professional_circuits',{'id':'c','project_id':'p','contract_version':1,
      'revision':2,'name':'Circuito','description':'','voltage_v':null,'phases':null,'notes':'',
      'created_at':'2026-10-01T10:00:00Z','updated_at':'2026-10-01T11:00:00Z'});
    await db.insert('professional_boards',{'id':'q','project_id':'p','contract_version':1,
      'revision':1,'name':'Quadro','description':'','location':'','notes':'',
      'created_at':'2026-10-01T10:00:00Z','updated_at':'2026-10-01T11:00:00Z'});

    await VisDatabase.upgradeSchemaForTesting(db,5,6);

    expect(await db.query('professional_projects'),hasLength(1));
    expect(await db.query('professional_circuits'),hasLength(1));
    expect(await db.query('professional_boards'),hasLength(1));
    final tables=await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='professional_protections'");
    expect(tables,hasLength(1));
    await db.close();
  });
}
