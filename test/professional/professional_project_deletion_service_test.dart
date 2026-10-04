import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_project_deletion_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
  });
  tearDown(() => db.close());

  test('deletes project graph and preserves another project', () async {
    final t = DateTime.utc(2026, 10, 4).toIso8601String();
    for (final id in ['gone', 'keep']) {
      await db.insert('professional_projects', {
        'id': id, 'contract_version': 1, 'revision': 1, 'name': id,
        'client': '', 'address': '', 'responsible': '', 'notes': '',
        'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_loads', {
        'id': '$id-l', 'project_id': id, 'contract_version': 1, 'revision': 1,
        'name': 'L', 'category': '', 'quantity': 1, 'power_w': 1.0,
        'voltage_v': 220.0, 'notes': '', 'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_circuits', {
        'id': '$id-c', 'project_id': id, 'contract_version': 1, 'revision': 1,
        'name': 'C', 'description': '', 'notes': '', 'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_circuit_loads', {'circuit_id': '$id-c', 'load_id': '$id-l'});
      await db.insert('professional_boards', {
        'id': '$id-b', 'project_id': id, 'contract_version': 1, 'revision': 1,
        'name': 'B', 'description': '', 'location': '', 'notes': '',
        'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_board_circuits', {'board_id': '$id-b', 'circuit_id': '$id-c'});
      await db.insert('professional_protections', {
        'id': '$id-pr', 'project_id': id, 'circuit_id': '$id-c',
        'contract_version': 2, 'revision': 1, 'name': 'DJ',
        'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_sizing', {
        'id': '$id-s', 'project_id': id, 'circuit_id': '$id-c',
        'contract_version': 1, 'revision': 1, 'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_materials', {
        'id': '$id-m', 'project_id': id, 'contract_version': 1, 'revision': 1,
        'description': 'Material', 'created_at': t, 'updated_at': t,
      });
      await db.insert('professional_memorials', {
        'id': '$id-mem', 'project_id': id, 'contract_version': 1, 'revision': 1,
        'created_at': t, 'updated_at': t,
      });
    }

    expect(await ProfessionalProjectDeletionService(db).deleteProject('gone'), isTrue);
    expect(await db.query('professional_projects', where: 'id = ?', whereArgs: ['gone']), isEmpty);
    expect(await db.query('professional_loads', where: 'project_id = ?', whereArgs: ['gone']), isEmpty);
    expect(await db.query('professional_circuits', where: 'project_id = ?', whereArgs: ['gone']), isEmpty);
    expect(await db.query('professional_boards', where: 'project_id = ?', whereArgs: ['gone']), isEmpty);
    for (final table in ['professional_protections', 'professional_sizing', 'professional_materials', 'professional_memorials']) {
      expect(await db.query(table, where: 'project_id = ?', whereArgs: ['gone']), isEmpty);
      expect(await db.query(table, where: 'project_id = ?', whereArgs: ['keep']), hasLength(1));
    }
    expect(await db.query('professional_circuit_loads', where: 'circuit_id = ?', whereArgs: ['gone-c']), isEmpty);
    expect(await db.query('professional_board_circuits', where: 'board_id = ?', whereArgs: ['gone-b']), isEmpty);
    expect(await db.query('professional_projects', where: 'id = ?', whereArgs: ['keep']), hasLength(1));
    expect(await db.query('professional_loads', where: 'project_id = ?', whereArgs: ['keep']), hasLength(1));
    expect(await db.query('professional_circuit_loads', where: 'circuit_id = ?', whereArgs: ['keep-c']), hasLength(1));
    expect(await db.query('professional_board_circuits', where: 'board_id = ?', whereArgs: ['keep-b']), hasLength(1));
  });
}
