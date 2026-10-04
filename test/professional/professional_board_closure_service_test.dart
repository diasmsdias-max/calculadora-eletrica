import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_board.dart';
import 'package:calculadora_eletrica/core/professional/professional_board_closure_service.dart';
import 'package:calculadora_eletrica/core/professional/professional_material.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Database db;
  final t = DateTime.utc(2026, 10, 4);

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    await db.insert('professional_projects', {
      'id':'p','contract_version':1,'revision':1,'name':'P','client':'',
      'address':'','responsible':'','notes':'','created_at':t.toIso8601String(),
      'updated_at':t.toIso8601String(),
    });
    await db.insert('professional_boards', {
      'id':'b','project_id':'p','contract_version':ProfessionalBoard.contractVersion,
      'revision':1,'name':'Q','description':'','location':'','notes':'',
      'status':'open','closed_at':null,'created_at':t.toIso8601String(),
      'updated_at':t.toIso8601String(),
    });
  });
  tearDown(() => db.close());

  ProfessionalBoard board() => ProfessionalBoard(
    id:'b',projectId:'p',revision:1,name:'Q',createdAt:t,updatedAt:t);

  ProfessionalMaterial material(String id,{double quantity=1}) => ProfessionalMaterial(
    id:id,projectId:'p',revision:1,description:'Disjuntor',category:'Proteções',
    unit:'un',quantity:quantity,source:'VIS:b',createdAt:t,updatedAt:t);

  test('closes board and replaces generated materials in one transaction',() async {
    await db.insert('professional_materials', {
      'id':'old','project_id':'p','contract_version':ProfessionalMaterial.contractVersion,
      'revision':1,'description':'Antigo','category':'','unit':'un','quantity':1.0,
      'source':'VIS:b','notes':'','created_at':t.toIso8601String(),
      'updated_at':t.toIso8601String(),
    });

    await ProfessionalBoardClosureService(db).closeBoard(
      board:board(),generatedMaterials:[material('new')],closedAt:t.add(const Duration(hours:1)));

    final b=(await db.query('professional_boards',where:'id = ?',whereArgs:['b'])).single;
    expect(b['status'],'closed');
    expect(b['closed_at'],isNotNull);
    final materials=await db.query('professional_materials',where:'project_id = ? AND source = ?',whereArgs:['p','VIS:b']);
    expect(materials.map((row)=>row['id']).toList(),['new']);
  });

  test('rolls back materials and board when generated material is invalid',() async {
    await db.insert('professional_materials', {
      'id':'old','project_id':'p','contract_version':ProfessionalMaterial.contractVersion,
      'revision':1,'description':'Antigo','category':'','unit':'un','quantity':1.0,
      'source':'VIS:b','notes':'','created_at':t.toIso8601String(),
      'updated_at':t.toIso8601String(),
    });

    expect(
      () => ProfessionalBoardClosureService(db).closeBoard(
        board:board(),generatedMaterials:[material('bad',quantity:0)],closedAt:t),
      throwsArgumentError,
    );

    final b=(await db.query('professional_boards',where:'id = ?',whereArgs:['b'])).single;
    expect(b['status'],'open');
    final materials=await db.query('professional_materials',where:'project_id = ? AND source = ?',whereArgs:['p','VIS:b']);
    expect(materials.map((row)=>row['id']).toList(),['old']);
  });
  test('reopening removes only generated board materials',() async {
    await db.update('professional_boards', {
      'status':'closed','closed_at':t.toIso8601String(),
    },where:'id = ?',whereArgs:['b']);
    for (final row in [
      {'id':'generated','source':'VIS:b'},
      {'id':'manual','source':'manual'},
    ]) {
      await db.insert('professional_materials', {
        'id':row['id'],'project_id':'p','contract_version':ProfessionalMaterial.contractVersion,
        'revision':1,'description':'Item','category':'','unit':'un','quantity':1.0,
        'source':row['source'],'notes':'','created_at':t.toIso8601String(),
        'updated_at':t.toIso8601String(),
      });
    }

    final closed=ProfessionalBoard(
      id:'b',projectId:'p',revision:1,name:'Q',status:ProfessionalBoardStatus.closed,
      closedAt:t,createdAt:t,updatedAt:t);
    await ProfessionalBoardClosureService(db).reopenBoard(
      board:closed,reopenedAt:t.add(const Duration(hours:1)));

    final b=(await db.query('professional_boards',where:'id = ?',whereArgs:['b'])).single;
    expect(b['status'],'open');
    expect(b['closed_at'],isNull);
    final materials=await db.query('professional_materials',where:'project_id = ?',whereArgs:['p']);
    expect(materials.map((row)=>row['id']).toList(),['manual']);
  });

  test('rejects empty board identity before database changes',() async {
    final service=ProfessionalBoardClosureService(db);
    final invalid=ProfessionalBoard(
      id:'',projectId:'p',revision:1,name:'Q',createdAt:t,updatedAt:t);

    expect(
      () => service.closeBoard(board:invalid,generatedMaterials:const[],closedAt:t),
      throwsArgumentError,
    );
    expect(
      () => service.reopenBoard(board:invalid,reopenedAt:t),
      throwsArgumentError,
    );

    final persisted=(await db.query('professional_boards',where:'id = ?',whereArgs:['b'])).single;
    expect(persisted['status'],'open');
  });

}
