import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_material.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_material_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';
void main(){sqfliteFfiInit();databaseFactory=databaseFactoryFfi;
 test('materials are isolated by project and quantity is optional',()async{
  final db=await databaseFactory.openDatabase(inMemoryDatabasePath,onConfigure:(d)=>d.execute('PRAGMA foreign_keys = ON'));
  await VisDatabase.createSchemaForTesting(db);final p=SqliteProfessionalProjectRepository(db),m=SqliteProfessionalMaterialRepository(db);
  final now=DateTime.utc(2026,10,1);for(final id in ['p1','p2'])await p.save(ProfessionalProject(id:id,revision:1,name:id,createdAt:now,updatedAt:now));
  await m.save(ProfessionalMaterial(id:'m1',projectId:'p1',revision:1,description:'Cabo',createdAt:now,updatedAt:now));
  await m.save(ProfessionalMaterial(id:'m2',projectId:'p2',revision:1,description:'Disjuntor',quantity:2,unit:'un',createdAt:now,updatedAt:now));
  expect(await m.getByProject('p1'),hasLength(1));expect((await m.getById('m1'))!.quantity,isNull);
  expect(()=>m.save(ProfessionalMaterial(id:'bad',projectId:'p1',revision:1,description:'X',quantity:0,createdAt:now,updatedAt:now)),throwsArgumentError);
  expect(()=>m.save(ProfessionalMaterial(id:'bad-project',projectId:'missing',revision:1,description:'X',createdAt:now,updatedAt:now)),throwsArgumentError);
  await db.close();
 });
 test('deleting project cascades materials',()async{
  final db=await databaseFactory.openDatabase(inMemoryDatabasePath,onConfigure:(d)=>d.execute('PRAGMA foreign_keys = ON'));
  await VisDatabase.createSchemaForTesting(db);final p=SqliteProfessionalProjectRepository(db),m=SqliteProfessionalMaterialRepository(db);
  final now=DateTime.utc(2026,10,1);await p.save(ProfessionalProject(id:'p',revision:1,name:'P',createdAt:now,updatedAt:now));
  await m.save(ProfessionalMaterial(id:'m',projectId:'p',revision:1,description:'Material',createdAt:now,updatedAt:now));
  await p.delete('p');expect(await m.getByProject('p'),isEmpty);await db.close();
 });}
