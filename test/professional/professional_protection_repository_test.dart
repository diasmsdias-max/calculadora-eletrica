import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_circuit_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_protection_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('protection belongs to circuit from same project', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final protections=SqliteProfessionalProtectionRepository(db);
    final now=DateTime.utc(2026,10,1);
    for(final id in ['p1','p2']) {
      await projects.save(ProfessionalProject(id:id,revision:1,name:'Projeto $id',
        createdAt:now,updatedAt:now));
    }
    await circuits.save(ProfessionalCircuit(id:'c1',projectId:'p1',revision:1,name:'C1',
      createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c2',projectId:'p2',revision:1,name:'C2',
      createdAt:now,updatedAt:now));

    await protections.save(ProfessionalProtection(id:'pr1',projectId:'p1',circuitId:'c1',
      revision:1,name:'Proteção',createdAt:now,updatedAt:now));
    expect(await protections.getByCircuit('c1'),hasLength(1));

    expect(()=>protections.save(ProfessionalProtection(id:'bad',projectId:'p1',circuitId:'c2',
      revision:1,name:'Inválida',createdAt:now,updatedAt:now)),throwsArgumentError);
    await db.close();
  });

  test('optional protection values validate only when informed', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final protections=SqliteProfessionalProtectionRepository(db);
    final now=DateTime.utc(2026,10,1);
    await projects.save(ProfessionalProject(id:'p',revision:1,name:'P',createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c',projectId:'p',revision:1,name:'C',
      createdAt:now,updatedAt:now));

    await protections.save(ProfessionalProtection(id:'empty-tech',projectId:'p',circuitId:'c',
      revision:1,name:'A definir',createdAt:now,updatedAt:now));
    expect((await protections.getById('empty-tech'))!.ratedCurrentA,isNull);

    expect(()=>protections.save(ProfessionalProtection(id:'bad-current',projectId:'p',circuitId:'c',
      revision:1,name:'X',ratedCurrentA:0,createdAt:now,updatedAt:now)),throwsArgumentError);
    expect(()=>protections.save(ProfessionalProtection(id:'bad-poles',projectId:'p',circuitId:'c',
      revision:1,name:'X',poles:5,createdAt:now,updatedAt:now)),throwsArgumentError);
    await db.close();
  });

  test('protection role round trips through sqlite', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final protections=SqliteProfessionalProtectionRepository(db);
    final now=DateTime.utc(2026,10,2);
    await projects.save(ProfessionalProject(id:'p-role',revision:1,name:'P',createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c-role',projectId:'p-role',revision:1,name:'C',
      createdAt:now,updatedAt:now));
    await protections.save(ProfessionalProtection(id:'pr-role',projectId:'p-role',circuitId:'c-role',
      revision:1,name:'Disjuntor',role:ProfessionalProtectionRole.overcurrent,
      ratedCurrentA:20,createdAt:now,updatedAt:now));

    final saved=await protections.getById('pr-role');
    expect(saved!.role,ProfessionalProtectionRole.overcurrent);
    expect(saved.ratedCurrentA,20);
    await db.close();
  });

  test('changing overcurrent protection to DR clears overcurrent validation metadata', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final protections=SqliteProfessionalProtectionRepository(db);
    final now=DateTime.utc(2026,10,2);
    await projects.save(ProfessionalProject(id:'p-change',revision:1,name:'P',createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c-change',projectId:'p-change',revision:1,name:'C',
      createdAt:now,updatedAt:now));
    await protections.save(ProfessionalProtection(
      id:'pr-change',projectId:'p-change',circuitId:'c-change',revision:1,name:'Proteção',
      role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:20,
      validationStatus:'valid',validationCriterion:'Ib ≤ In ≤ Iz',
      createdAt:now,updatedAt:now,
    ));
    await protections.save(ProfessionalProtection(
      id:'pr-change',projectId:'p-change',circuitId:'c-change',revision:2,name:'Proteção',
      role:ProfessionalProtectionRole.residualCurrent,ratedCurrentA:30,
      validationStatus:'',validationCriterion:'',
      createdAt:now,updatedAt:now.add(const Duration(minutes:1)),
    ));

    final saved=await protections.getById('pr-change');
    expect(saved!.role,ProfessionalProtectionRole.residualCurrent);
    expect(saved.validationStatus,isEmpty);
    expect(saved.validationCriterion,isEmpty);
    await db.close();
  });

  test('deleting circuit cascades its protections', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final protections=SqliteProfessionalProtectionRepository(db);
    final now=DateTime.utc(2026,10,1);
    await projects.save(ProfessionalProject(id:'p',revision:1,name:'P',createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c',projectId:'p',revision:1,name:'C',
      createdAt:now,updatedAt:now));
    await protections.save(ProfessionalProtection(id:'pr',projectId:'p',circuitId:'c',
      revision:1,name:'Dispositivo',createdAt:now,updatedAt:now));
    await circuits.delete('c');
    expect(await protections.getByProject('p'),isEmpty);
    await db.close();
  });
}
