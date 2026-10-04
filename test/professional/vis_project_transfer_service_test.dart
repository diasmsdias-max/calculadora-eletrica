import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/vis_project_transfer_service.dart';

void main(){
  sqfliteFfiInit(); databaseFactory=databaseFactoryFfi;
  late Database db;
  setUp(() async {db=await databaseFactory.openDatabase(inMemoryDatabasePath);await db.execute('PRAGMA foreign_keys = ON');await VisDatabase.createSchemaForTesting(db);});
  tearDown(() => db.close());

  test('database VIS Project round trip replaces same project and preserves graph',() async{
    final t=DateTime.utc(2026,10,1).toIso8601String();
    await db.insert('professional_projects',{'id':'p','contract_version':1,'revision':2,'name':'Projeto','client':'Cliente','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_loads',{'id':'l','project_id':'p','contract_version':1,'revision':1,'name':'Motor','category':'','quantity':1,'power_w':1500.0,'voltage_v':220.0,'power_factor':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuits',{'id':'c','project_id':'p','contract_version':1,'revision':3,'name':'C1','description':'','voltage_v':null,'phases':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuit_loads',{'circuit_id':'c','load_id':'l'});
    await db.insert('professional_boards',{'id':'b','project_id':'p','contract_version':1,'revision':1,'name':'QD1','description':'','location':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_board_circuits',{'board_id':'b','circuit_id':'c'});
    await db.insert('professional_protections',{'id':'pr','project_id':'p','circuit_id':'c','contract_version':1,'revision':1,'name':'DJ','device_type':'','rated_current_a':null,'poles':null,'trip_curve':'','breaking_capacity_ka':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_sizing',{'id':'s','project_id':'p','circuit_id':'c','contract_version':1,'revision':1,'design_current_a':null,'conductor_section_mm2':null,'voltage_drop_percent':null,'protection_current_a':null,'method':'','criteria':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_materials',{'id':'m','project_id':'p','contract_version':1,'revision':1,'description':'Cabo','category':'','unit':'m','quantity':null,'source':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_memorials',{'id':'mem','project_id':'p','contract_version':1,'revision':1,'title':'Memorial','scope':'','criteria':'','conclusions':'','notes':'','created_at':t,'updated_at':t});

    final service=VisProjectTransferService(db);
    final source=await service.exportProject('p');

    await db.delete('professional_projects',where:'id = ?',whereArgs:['p']);
    await db.insert('professional_projects',{'id':'p','contract_version':1,'revision':99,'name':'Obsoleto','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_loads',{'id':'old','project_id':'p','contract_version':1,'revision':1,'name':'Antiga','category':'','quantity':1,'power_w':1.0,'voltage_v':1.0,'power_factor':null,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_materials',{'id':'old-m','project_id':'p','contract_version':1,'revision':1,'description':'Material antigo','created_at':t,'updated_at':t});
    await db.insert('professional_memorials',{'id':'old-mem','project_id':'p','contract_version':1,'revision':1,'title':'Memorial antigo','created_at':t,'updated_at':t});

    await service.importProject(source);

    expect((await db.query('professional_projects')).single['revision'],2);
    expect((await db.query('professional_loads')).single['id'],'l');
    expect(await db.query('professional_loads',where:'id = ?',whereArgs:['old']),isEmpty);
    expect(await db.query('professional_materials',where:'id = ?',whereArgs:['old-m']),isEmpty);
    expect(await db.query('professional_memorials',where:'id = ?',whereArgs:['old-mem']),isEmpty);
    expect((await db.query('professional_circuit_loads')).single,containsPair('load_id','l'));
    expect((await db.query('professional_board_circuits')).single,containsPair('circuit_id','c'));
    for(final table in ['professional_circuits','professional_boards','professional_protections','professional_sizing','professional_materials','professional_memorials']){
      expect(await db.query(table),hasLength(1),reason:table);
    }
  });

  test('VIS Project round trip preserves board and protection V2 contracts',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    await db.insert('professional_projects',{'id':'p2','contract_version':1,'revision':1,'name':'Projeto V2','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuits',{'id':'c2','project_id':'p2','contract_version':1,'revision':1,'name':'C2','description':'','voltage_v':220.0,'phases':1,'notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_boards',{'id':'b2','project_id':'p2','contract_version':2,'revision':3,'name':'QD2','description':'','location':'Casa de máquinas','notes':'','status':'closed','closed_at':t,'created_at':t,'updated_at':t});
    await db.insert('professional_board_circuits',{'board_id':'b2','circuit_id':'c2'});
    await db.insert('professional_protections',{'id':'pr2','project_id':'p2','circuit_id':'c2','contract_version':2,'revision':4,'name':'DJ C2','device_type':'Disjuntor','protection_role':'overcurrent','rated_current_a':32.0,'recommended_current_a':25.0,'validation_status':'warning','validation_criterion':'Ib <= In <= Iz','poles':2,'trip_curve':'C','breaking_capacity_ka':6.0,'notes':'Adotado pelo técnico','created_at':t,'updated_at':t});

    final service=VisProjectTransferService(db);
    final source=await service.exportProject('p2');
    await db.delete('professional_projects',where:'id = ?',whereArgs:['p2']);
    await service.importProject(source);

    final board=(await db.query('professional_boards',where:'id = ?',whereArgs:['b2'])).single;
    expect(board['contract_version'],2);
    expect(board['status'],'closed');
    expect(board['closed_at'],t);
    expect(board['location'],'Casa de máquinas');

    final protection=(await db.query('professional_protections',where:'id = ?',whereArgs:['pr2'])).single;
    expect(protection['contract_version'],2);
    expect(protection['protection_role'],'overcurrent');
    expect(protection['rated_current_a'],32.0);
    expect(protection['recommended_current_a'],25.0);
    expect(protection['validation_status'],'warning');
    expect(protection['validation_criterion'],'Ib <= In <= Iz');
    expect(protection['poles'],2);
    expect(protection['trip_curve'],'C');
    expect(protection['breaking_capacity_ka'],6.0);
    expect(protection['notes'],'Adotado pelo técnico');
    expect((await db.query('professional_board_circuits')).single,containsPair('circuit_id','c2'));
  });

  test('failed same-id import rolls back existing project',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    await db.insert('professional_projects',{'id':'rollback','contract_version':1,'revision':7,'name':'Original','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_loads',{'id':'rollback-l','project_id':'rollback','contract_version':1,'revision':1,'name':'Carga original','quantity':1,'power_w':100.0,'voltage_v':220.0,'created_at':t,'updated_at':t});
    final service=VisProjectTransferService(db);
    final exported=await service.exportProject('rollback');
    final json=jsonDecode(exported) as Map<String,dynamic>;
    final relations=json['relations'] as Map<String,dynamic>;
    relations['circuitLoads']={'missing-circuit':['rollback-l']};
    final invalid=jsonEncode(json);

    await expectLater(service.importProject(invalid),throwsA(anything));

    final project=(await db.query('professional_projects',where:'id = ?',whereArgs:['rollback'])).single;
    expect(project['revision'],7);
    expect(project['name'],'Original');
    final loads=await db.query('professional_loads',where:'project_id = ?',whereArgs:['rollback']);
    expect(loads,hasLength(1));
    expect(loads.single['id'],'rollback-l');
  });

  test('duplicate sizing is rejected before replacing same-id project',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    await db.insert('professional_projects',{'id':'atomic','contract_version':1,'revision':9,'name':'Original atomic','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuits',{'id':'atomic-c','project_id':'atomic','contract_version':1,'revision':1,'name':'C1','created_at':t,'updated_at':t});
    final service=VisProjectTransferService(db);
    final exported=await service.exportProject('atomic');
    final json=jsonDecode(exported) as Map<String,dynamic>;
    json['sizing']=[
      {'contractVersion':1,'id':'s1','projectId':'atomic','circuitId':'atomic-c','revision':1,'method':'','criteria':'','notes':'','createdAt':t,'updatedAt':t},
      {'contractVersion':1,'id':'s2','projectId':'atomic','circuitId':'atomic-c','revision':1,'method':'','criteria':'','notes':'','createdAt':t,'updatedAt':t},
    ];

    await expectLater(service.importProject(jsonEncode(json)),throwsA(anything));

    final project=(await db.query('professional_projects',where:'id = ?',whereArgs:['atomic'])).single;
    expect(project['revision'],9);
    expect(project['name'],'Original atomic');
    expect(await db.query('professional_circuits',where:'project_id = ?',whereArgs:['atomic']),hasLength(1));
    expect(await db.query('professional_sizing',where:'project_id = ?',whereArgs:['atomic']),isEmpty);
  });

  test('import rejects empty root project id before database write',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    final source=jsonEncode({
      'format':'VISPROJECT',
      'contractVersion':1,
      'project':{'contractVersion':1,'id':'','revision':1,'name':'Inválido','client':'','address':'','responsible':'','notes':'','createdAt':t,'updatedAt':t},
      'loads':[],
      'circuits':[],
      'boards':[],
      'protections':[],
      'sizing':[],
      'materials':[],
      'relations':{'circuitLoads':{},'boardCircuits':{}},
    });

    await expectLater(VisProjectTransferService(db).importProject(source),throwsA(isA<FormatException>()));
    expect(await db.query('professional_projects'),isEmpty);
  });

  test('import rejects duplicate circuit-load relation',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    await db.insert('professional_projects',{'id':'dup-cl','contract_version':1,'revision':1,'name':'Projeto','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_loads',{'id':'l','project_id':'dup-cl','contract_version':1,'revision':1,'name':'Carga','quantity':1,'power_w':100.0,'voltage_v':220.0,'created_at':t,'updated_at':t});
    await db.insert('professional_circuits',{'id':'c','project_id':'dup-cl','contract_version':1,'revision':1,'name':'C1','created_at':t,'updated_at':t});
    final service=VisProjectTransferService(db);
    final json=jsonDecode(await service.exportProject('dup-cl')) as Map<String,dynamic>;
    (json['relations'] as Map<String,dynamic>)['circuitLoads']={'c':['l','l']};
    await expectLater(service.importProject(jsonEncode(json)),throwsA(isA<FormatException>()));
  });

  test('import rejects duplicate board-circuit relation',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    await db.insert('professional_projects',{'id':'dup-bc','contract_version':1,'revision':1,'name':'Projeto','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    await db.insert('professional_circuits',{'id':'c','project_id':'dup-bc','contract_version':1,'revision':1,'name':'C1','created_at':t,'updated_at':t});
    await db.insert('professional_boards',{'id':'b','project_id':'dup-bc','contract_version':1,'revision':1,'name':'QD1','created_at':t,'updated_at':t});
    final service=VisProjectTransferService(db);
    final json=jsonDecode(await service.exportProject('dup-bc')) as Map<String,dynamic>;
    (json['relations'] as Map<String,dynamic>)['boardCircuits']={'b':['c','c']};
    await expectLater(service.importProject(jsonEncode(json)),throwsA(isA<FormatException>()));
  });

  test('import rejects memorial with empty id',() async{
    final t=DateTime.utc(2026,10,4).toIso8601String();
    await db.insert('professional_projects',{'id':'mem-id','contract_version':1,'revision':1,'name':'Projeto','client':'','address':'','responsible':'','notes':'','created_at':t,'updated_at':t});
    final service=VisProjectTransferService(db);
    final json=jsonDecode(await service.exportProject('mem-id')) as Map<String,dynamic>;
    json['memorial']={'contractVersion':1,'id':'','projectId':'mem-id','revision':1,'title':'Memorial','scope':'','criteria':'','conclusions':'','notes':'','createdAt':t,'updatedAt':t};

    await expectLater(service.importProject(jsonEncode(json)),throwsA(isA<FormatException>()));
    final projects=await db.query('professional_projects',where:'id = ?',whereArgs:['mem-id']);
    expect(projects,hasLength(1));
  });

  test('export rejects unknown professional project',() async{
    await expectLater(VisProjectTransferService(db).exportProject('missing'),throwsArgumentError);
  });
}
