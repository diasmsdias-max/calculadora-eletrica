import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_load_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('professional loads stay isolated by project and cascade on delete', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects = SqliteProfessionalProjectRepository(db);
    final loads = SqliteProfessionalLoadRepository(db);
    final now = DateTime.utc(2026, 10, 1);

    for (final id in ['p1', 'p2']) {
      await projects.save(ProfessionalProject(
        id: id,
        revision: 1,
        name: 'Projeto $id',
        createdAt: now,
        updatedAt: now,
      ));
    }

    await loads.save(ProfessionalLoad(
      id: 'l1',
      projectId: 'p1',
      revision: 1,
      name: 'Motor',
      quantity: 2,
      powerW: 1100,
      voltageV: 220,
      createdAt: now,
      updatedAt: now,
    ));
    await loads.save(ProfessionalLoad(
      id: 'l2',
      projectId: 'p2',
      revision: 1,
      name: 'Iluminação',
      powerW: 100,
      voltageV: 127,
      createdAt: now,
      updatedAt: now,
    ));

    expect(await loads.getByProject('p1'), hasLength(1));
    expect((await loads.getByProject('p1')).single.totalPowerW, 2200);

    await projects.delete('p1');
    expect(await loads.getByProject('p1'), isEmpty);
    expect(await loads.getByProject('p2'), hasLength(1));
    await db.close();
  });


  test('professional load repository preserves simultaneity metadata', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final projects = SqliteProfessionalProjectRepository(db);
    final loads = SqliteProfessionalLoadRepository(db);
    final now = DateTime.utc(2026, 10, 2);

    await projects.save(ProfessionalProject(
      id: 'p-fs',
      revision: 1,
      name: 'Projeto FS',
      createdAt: now,
      updatedAt: now,
    ));
    await loads.save(ProfessionalLoad(
      id: 'l-fs',
      projectId: 'p-fs',
      revision: 1,
      name: 'Motores',
      quantity: 4,
      powerW: 10000,
      voltageV: 220,
      simultaneityFactor: 0.75,
      simultaneitySource: 'visEstimate',
      simultaneityBasis: '3 de 4 unidades informadas como simultâneas.',
      createdAt: now,
      updatedAt: now,
    ));

    final saved = (await loads.getByProject('p-fs')).single;
    expect(saved.simultaneityFactor, 0.75);
    expect(saved.simultaneitySource, 'visEstimate');
    expect(saved.simultaneityBasis, contains('3 de 4'));
    await db.close();
  });

  test('professional load repository rejects incomplete identity', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await VisDatabase.createSchemaForTesting(db);
    final loads = SqliteProfessionalLoadRepository(db);
    final now = DateTime.utc(2026, 10, 1);

    expect(
      () => loads.save(ProfessionalLoad(
        id: '',
        projectId: '',
        revision: 1,
        name: '',
        createdAt: now,
        updatedAt: now,
      )),
      throwsArgumentError,
    );
    await db.close();
  });
}
