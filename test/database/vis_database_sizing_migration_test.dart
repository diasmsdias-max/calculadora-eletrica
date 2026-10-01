import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
void main(){sqfliteFfiInit();databaseFactory=databaseFactoryFfi;
 test('schema 6 to 7 adds sizing without losing existing data',()async{
  final db=await databaseFactory.openDatabase(inMemoryDatabasePath,onConfigure:(d)=>d.execute('PRAGMA foreign_keys = ON'));
  await db.execute('''CREATE TABLE professional_projects (id TEXT PRIMARY KEY, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, name TEXT NOT NULL, client TEXT NOT NULL DEFAULT '', address TEXT NOT NULL DEFAULT '', responsible TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
  await db.execute('''CREATE TABLE professional_circuits (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', voltage_v REAL, phases INTEGER, notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE)''');
  await db.execute('''CREATE TABLE professional_protections (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, circuit_id TEXT NOT NULL, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, name TEXT NOT NULL, device_type TEXT NOT NULL DEFAULT '', rated_current_a REAL, poles INTEGER, trip_curve TEXT NOT NULL DEFAULT '', breaking_capacity_ka REAL, notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(project_id) REFERENCES professional_projects(id) ON DELETE CASCADE, FOREIGN KEY(circuit_id) REFERENCES professional_circuits(id) ON DELETE CASCADE)''');
  const t='2026-10-01T10:00:00Z';
  await db.insert('professional_projects',{'id':'p','contract_version':1,'revision':1,'name':'P','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
  await db.insert('professional_circuits',{'id':'c','project_id':'p','contract_version':1,'revision':1,'name':'C','description':'','voltage_v':null,'phases':null,'notes':'','created_at':t,'updated_at':t});
  await db.insert('professional_protections',{'id':'pr','project_id':'p','circuit_id':'c','contract_version':1,'revision':1,'name':'PR','device_type':'','rated_current_a':null,'poles':null,'trip_curve':'','breaking_capacity_ka':null,'notes':'','created_at':t,'updated_at':t});
  await VisDatabase.upgradeSchemaForTesting(db,6,7);
  expect(await db.query('professional_projects'),hasLength(1));expect(await db.query('professional_circuits'),hasLength(1));expect(await db.query('professional_protections'),hasLength(1));
  final tables=await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='professional_sizing'");expect(tables,hasLength(1));await db.close();
 });}
