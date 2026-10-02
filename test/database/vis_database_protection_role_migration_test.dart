import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('schema 12 to 13 adds protection role without classifying legacy data', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('''CREATE TABLE professional_protections (
      id TEXT PRIMARY KEY,
      project_id TEXT NOT NULL,
      circuit_id TEXT NOT NULL,
      contract_version INTEGER NOT NULL,
      revision INTEGER NOT NULL,
      name TEXT NOT NULL,
      device_type TEXT NOT NULL DEFAULT '',
      rated_current_a REAL,
      recommended_current_a REAL,
      validation_status TEXT,
      validation_criterion TEXT NOT NULL DEFAULT '',
      poles INTEGER,
      trip_curve TEXT NOT NULL DEFAULT '',
      breaking_capacity_ka REAL,
      notes TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )''');
    await db.insert('professional_protections',{
      'id':'legacy-pr','project_id':'p','circuit_id':'c','contract_version':1,
      'revision':1,'name':'Proteção existente','device_type':'Disjuntor',
      'rated_current_a':20.0,'validation_criterion':'','trip_curve':'C','notes':'',
      'created_at':'2026-10-01T10:00:00Z','updated_at':'2026-10-01T10:00:00Z',
    });

    await VisDatabase.upgradeSchemaForTesting(db,12,13);

    final columns=await db.rawQuery('PRAGMA table_info(professional_protections)');
    expect(columns.map((e)=>e['name']),contains('protection_role'));
    final rows=await db.query('professional_protections',where:'id = ?',whereArgs:['legacy-pr']);
    expect(rows,hasLength(1));
    expect(rows.single['name'],'Proteção existente');
    expect(rows.single['rated_current_a'],20.0);
    expect(rows.single['protection_role'],isNull);
    await db.close();
  });
}
