import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
void main(){sqfliteFfiInit();databaseFactory=databaseFactoryFfi;
 test('schema 7 to 8 adds materials without losing sizing',()async{
  final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
  await db.execute('''CREATE TABLE professional_projects (id TEXT PRIMARY KEY, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, name TEXT NOT NULL, client TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '', responsible TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE professional_circuits (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', voltage_v REAL, phases INTEGER, notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE)''');
  await db.execute('''CREATE TABLE professional_sizing (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, circuit_id TEXT NOT NULL UNIQUE, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, design_current_a REAL, conductor_section_mm2 REAL, voltage_drop_percent REAL, protection_current_a REAL, method TEXT NOT NULL DEFAULT '', criteria TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE, FOREIGN KEY(circuit_id) REFERENCES professional_circuits(id) ON DELETE CASCADE)''');
  const t='2026-10-01T10:00:00Z';
  await db.insert('professional_projects',{'id':'p','contract_version':1,'revision':1,'name':'P','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
  await db.insert('professional_circuits',{'id':'c','project_id':'p','contract_version':1,'revision':1,'name':'C','description':'','voltage_v':null,'phases':null,'notes':'','created_at':t,'updated_at':t});
  await db.insert('professional_sizing',{'id':'s','project_id':'p','circuit_id':'c','contract_version':1,'revision':1,'design_current_a':null,'conductor_section_mm2':null,'voltage_drop_percent':null,'protection_current_a':null,'method':'','criteria':'','notes':'','created_at':t,'updated_at':t});
  await VisDatabase.upgradeSchemaForTesting(db,7,8);
  expect(await db.query('professional_sizing'),hasLength(1));
  final tables=await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='professional_materials'");expect(tables,hasLength(1));await db.close();
 });}
