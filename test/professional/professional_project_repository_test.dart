import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vis_electrica/core/database/vis_database.dart';
import 'package:vis_electrica/core/professional/professional_project.dart';
import 'package:vis_electrica/core/professional/sqlite_professional_project_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('professional project round-trips portable contract', () {
    final project = ProfessionalProject(
      id: 'project-01',
      revision: 3,
      name: '  Galpão A  ',
      client: ' Cliente ',
      createdAt: DateTime.parse('2026-10-01T10:00:00-03:00'),
      updatedAt: DateTime.parse('2026-10-01T11:00:00-03:00'),
    ).normalized();

    final restored = ProfessionalProject.fromPortableJson(
      project.toPortableJson(),
    );

    expect(restored.id, 'project-01');
    expect(restored.name, 'Galpão A');
    expect(restored.client, 'Cliente');
    expect(restored.revision, 3);
    expect(restored.createdAt.isUtc, isTrue);
  });

  test('copyWith keeps stable id and increments revision', () {
    final now = DateTime.utc(2026, 10, 1);
    final original = ProfessionalProject(
      id: 'stable-id',
      revision: 1,
      name: 'Projeto',
      createdAt: now,
      updatedAt: now,
    );

    final edited = original.copyWith(
      name: 'Projeto revisado',
      updatedAt: now.add(const Duration(hours: 1)),
    );

    expect(edited.id, original.id);
    expect(edited.revision, 2);
    expect(edited.name, 'Projeto revisado');
  });

  test('sqlite repository is isolated from legacy projects table', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await VisDatabase.createSchemaForTesting(db);
    final repository = SqliteProfessionalProjectRepository(db);
    final now = DateTime.utc(2026, 10, 1);

    await repository.save(ProfessionalProject(
      id: 'professional-01',
      revision: 1,
      name: 'Projeto Profissional',
      createdAt: now,
      updatedAt: now,
    ));

    final professional = await repository.getAll();
    final legacyRows = await db.query('projects');

    expect(professional, hasLength(1));
    expect(professional.single.id, 'professional-01');
    expect(legacyRows, isEmpty);
    await db.close();
  });

  test('repository rejects empty id or name', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await VisDatabase.createSchemaForTesting(db);
    final repository = SqliteProfessionalProjectRepository(db);
    final now = DateTime.utc(2026, 10, 1);

    expect(
      () => repository.save(ProfessionalProject(
        id: '',
        revision: 1,
        name: 'Projeto',
        createdAt: now,
        updatedAt: now,
      )),
      throwsArgumentError,
    );
    await db.close();
  });
}
