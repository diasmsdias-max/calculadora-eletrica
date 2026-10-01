import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_circuit_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_load_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('circuit accepts only loads from its own project', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects = SqliteProfessionalProjectRepository(db);
    final loads = SqliteProfessionalLoadRepository(db);
    final circuits = SqliteProfessionalCircuitRepository(db);
    final now = DateTime.utc(2026, 10, 1);

    for (final id in ['p1', 'p2']) {
      await projects.save(ProfessionalProject(
        id: id, revision: 1, name: 'Projeto $id',
        createdAt: now, updatedAt: now));
    }
    for (final pair in [('l1', 'p1'), ('l2', 'p2')]) {
      await loads.save(ProfessionalLoad(
        id: pair.$1, projectId: pair.$2, revision: 1, name: 'Carga ${pair.$1}',
        powerW: 100, voltageV: 127, createdAt: now, updatedAt: now));
    }
    await circuits.save(ProfessionalCircuit(
      id: 'c1', projectId: 'p1', revision: 1, name: 'Circuito 1',
      createdAt: now, updatedAt: now));

    await circuits.replaceLoads('c1', ['l1']);
    expect(await circuits.getLoadIds('c1'), ['l1']);

    expect(() => circuits.replaceLoads('c1', ['l2']), throwsArgumentError);
    expect(await circuits.getLoadIds('c1'), ['l1']);

    await db.close();
  });

  test('deleting load or circuit cleans relation table', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects = SqliteProfessionalProjectRepository(db);
    final loads = SqliteProfessionalLoadRepository(db);
    final circuits = SqliteProfessionalCircuitRepository(db);
    final now = DateTime.utc(2026, 10, 1);

    await projects.save(ProfessionalProject(id: 'p', revision: 1, name: 'P',
      createdAt: now, updatedAt: now));
    await loads.save(ProfessionalLoad(id: 'l', projectId: 'p', revision: 1,
      name: 'Carga', powerW: 10, voltageV: 127, createdAt: now, updatedAt: now));
    await circuits.save(ProfessionalCircuit(id: 'c', projectId: 'p', revision: 1,
      name: 'Circuito', createdAt: now, updatedAt: now));
    await circuits.replaceLoads('c', ['l']);

    await loads.delete('l');
    expect(await circuits.getLoadIds('c'), isEmpty);

    await db.close();
  });
}
