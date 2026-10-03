import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_board.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_board_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_circuit_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('schema 15 to 16 adds board closure columns with open default',() async{
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('CREATE TABLE professional_boards (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, contract_version INTEGER NOT NULL, revision INTEGER NOT NULL, name TEXT NOT NULL, description TEXT NOT NULL DEFAULT \'\', location TEXT NOT NULL DEFAULT \'\', notes TEXT NOT NULL DEFAULT \'\', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    final t=DateTime.utc(2026,10,1).toIso8601String();
    await db.insert('professional_boards',{'id':'b','project_id':'p','contract_version':1,'revision':1,'name':'QD1','created_at':t,'updated_at':t});
    await VisDatabase.upgradeSchemaForTesting(db,15,16);
    final row=(await db.query('professional_boards')).single;
    expect(row['status'],'open');expect(row['closed_at'],isNull);
    await db.close();
  });

  test('board accepts only circuits from its project and circuit has one board', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final boards=SqliteProfessionalBoardRepository(db);
    final now=DateTime.utc(2026,10,1);
    for(final id in ['p1','p2']) {
      await projects.save(ProfessionalProject(id:id,revision:1,name:'Projeto $id',
        createdAt:now,updatedAt:now));
    }
    await circuits.save(ProfessionalCircuit(id:'c1',projectId:'p1',revision:1,name:'C1',
      createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c2',projectId:'p2',revision:1,name:'C2',
      createdAt:now,updatedAt:now));
    for(final id in ['q1','q2']) {
      await boards.save(ProfessionalBoard(id:id,projectId:'p1',revision:1,name:'Quadro $id',
        createdAt:now,updatedAt:now));
    }

    await boards.replaceCircuits('q1',['c1']);
    expect(await boards.getCircuitIds('q1'),['c1']);
    expect(()=>boards.replaceCircuits('q1',['c2']),throwsArgumentError);
    expect(await boards.getCircuitIds('q1'),['c1']);

    expect(()=>boards.replaceCircuits('q2',['c1']),
      throwsA(anything));
    expect(await boards.getCircuitIds('q1'),['c1']);
    expect(await boards.getCircuitIds('q2'),isEmpty);
    await db.close();
  });

  test('deleting board removes assignment but preserves circuit', () async {
    final db=await databaseFactory.openDatabase(inMemoryDatabasePath); await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects=SqliteProfessionalProjectRepository(db);
    final circuits=SqliteProfessionalCircuitRepository(db);
    final boards=SqliteProfessionalBoardRepository(db);
    final now=DateTime.utc(2026,10,1);
    await projects.save(ProfessionalProject(id:'p',revision:1,name:'P',createdAt:now,updatedAt:now));
    await circuits.save(ProfessionalCircuit(id:'c',projectId:'p',revision:1,name:'C',
      createdAt:now,updatedAt:now));
    await boards.save(ProfessionalBoard(id:'q',projectId:'p',revision:1,name:'Q',
      createdAt:now,updatedAt:now));
    await boards.replaceCircuits('q',['c']);
    await boards.delete('q');
    expect(await circuits.getById('c'),isNotNull);
    final links=await db.query('professional_board_circuits');
    expect(links,isEmpty);
    await db.close();
  });
}
