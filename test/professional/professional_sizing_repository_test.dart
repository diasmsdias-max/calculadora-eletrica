import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/professional_sizing.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_circuit_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_sizing_repository.dart';

void main(){
 sqfliteFfiInit();databaseFactory=databaseFactoryFfi;
 Future<(Database,SqliteProfessionalCircuitRepository,SqliteProfessionalSizingRepository)> setup()async{
  final db=await databaseFactory.openDatabase(inMemoryDatabasePath,onConfigure:(d)=>d.execute('PRAGMA foreign_keys = ON'));
  await VisDatabase.createSchemaForTesting(db);final p=SqliteProfessionalProjectRepository(db);
  final c=SqliteProfessionalCircuitRepository(db);final s=SqliteProfessionalSizingRepository(db);final now=DateTime.utc(2026,10,1);
  for(final id in ['p1','p2'])await p.save(ProfessionalProject(id:id,revision:1,name:id,createdAt:now,updatedAt:now));
  await c.save(ProfessionalCircuit(id:'c1',projectId:'p1',revision:1,name:'C1',createdAt:now,updatedAt:now));
  await c.save(ProfessionalCircuit(id:'c2',projectId:'p2',revision:1,name:'C2',createdAt:now,updatedAt:now));
  return(db,c,s);
 }
 test('sizing accepts only circuit from same project',()async{
  final (db,_,s)=await setup();final now=DateTime.utc(2026,10,1);
  await s.save(ProfessionalSizing(id:'s1',projectId:'p1',circuitId:'c1',revision:1,createdAt:now,updatedAt:now));
  expect((await s.getByCircuit('c1'))?.id,'s1');
  expect(()=>s.save(ProfessionalSizing(id:'bad',projectId:'p1',circuitId:'c2',revision:1,createdAt:now,updatedAt:now)),throwsArgumentError);
  await db.close();
 });
 test('sizing validates informed values and circuit is unique',()async{
  final (db,_,s)=await setup();final now=DateTime.utc(2026,10,1);
  await s.save(ProfessionalSizing(id:'s1',projectId:'p1',circuitId:'c1',revision:1,createdAt:now,updatedAt:now));
  expect(()=>s.save(ProfessionalSizing(id:'s2',projectId:'p1',circuitId:'c1',revision:1,createdAt:now,updatedAt:now)),throwsA(anything));
  expect(()=>s.save(ProfessionalSizing(id:'bad',projectId:'p1',circuitId:'c1',revision:1,designCurrentA:0,createdAt:now,updatedAt:now)),throwsArgumentError);
  expect(()=>s.save(ProfessionalSizing(id:'bad2',projectId:'p1',circuitId:'c1',revision:1,voltageDropPercent:101,createdAt:now,updatedAt:now)),throwsArgumentError);
  await db.close();
 });
 test('deleting circuit cascades sizing',()async{
  final (db,c,s)=await setup();final now=DateTime.utc(2026,10,1);
  await s.save(ProfessionalSizing(id:'s1',projectId:'p1',circuitId:'c1',revision:1,createdAt:now,updatedAt:now));
  await c.delete('c1');expect(await s.getByCircuit('c1'),isNull);await db.close();
 });
}
