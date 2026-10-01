import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_memorial.dart';
import 'package:calculadora_eletrica/core/professional/professional_project.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_memorial_repository.dart';
import 'package:calculadora_eletrica/core/professional/sqlite_professional_project_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('one memorial is persisted per professional project', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'));
    await VisDatabase.createSchemaForTesting(db);
    final projects = SqliteProfessionalProjectRepository(db);
    final memorials = SqliteProfessionalMemorialRepository(db);
    final now = DateTime.utc(2026, 10, 1);
    await projects.save(ProfessionalProject(id: 'p1', revision: 1, name: 'Projeto', createdAt: now, updatedAt: now));
    await memorials.save(ProfessionalMemorial(id: 'm1', projectId: 'p1', revision: 1,
      title: 'Memorial', scope: 'Escopo confirmado', createdAt: now, updatedAt: now));
    final saved = await memorials.getByProject('p1');
    expect(saved, isNotNull);
    expect(saved!.title, 'Memorial');
    expect(saved.scope, 'Escopo confirmado');
    expect(() => memorials.save(ProfessionalMemorial(id: 'm2', projectId: 'missing', revision: 1,
      createdAt: now, updatedAt: now)), throwsArgumentError);
    await db.close();
  });

  test('deleting project cascades memorial', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'));
    await VisDatabase.createSchemaForTesting(db);
    final projects = SqliteProfessionalProjectRepository(db);
    final memorials = SqliteProfessionalMemorialRepository(db);
    final now = DateTime.utc(2026, 10, 1);
    await projects.save(ProfessionalProject(id: 'p', revision: 1, name: 'P', createdAt: now, updatedAt: now));
    await memorials.save(ProfessionalMemorial(id: 'm', projectId: 'p', revision: 1, createdAt: now, updatedAt: now));
    await projects.delete('p');
    expect(await memorials.getByProject('p'), isNull);
    await db.close();
  });
}
