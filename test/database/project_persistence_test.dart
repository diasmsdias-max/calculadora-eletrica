import 'dart:convert';

import 'package:calculadora_eletrica/core/database/local_project.dart';
import 'package:calculadora_eletrica/core/database/project_record.dart';
import 'package:calculadora_eletrica/core/database/project_record_repository.dart';
import 'package:calculadora_eletrica/core/database/project_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('LocalProject survives JSON round trip', () {
    final created = DateTime.utc(2026, 9, 30, 1);
    final updated = DateTime.utc(2026, 9, 30, 2);
    final project = LocalProject(
      id: 'p1',
      name: 'Obra A',
      client: 'Cliente',
      address: 'Endereço',
      responsible: 'Responsável',
      notes: 'Notas',
      createdAt: created,
      updatedAt: updated,
    );
    final restored = LocalProject.fromJson(project.toJson());
    expect(restored.id, project.id);
    expect(restored.name, project.name);
    expect(restored.client, project.client);
    expect(restored.address, project.address);
    expect(restored.responsible, project.responsible);
    expect(restored.notes, project.notes);
    expect(restored.createdAt, created);
    expect(restored.updatedAt, updated);
  });

  test('project repository saves, updates, sorts and deletes', () async {
    final repository = PreferencesProjectRepository();
    final old = LocalProject(
      id: 'old', name: 'Antigo', client: '', address: '', responsible: '',
      notes: '', createdAt: DateTime.utc(2026, 9, 1), updatedAt: DateTime.utc(2026, 9, 1),
    );
    final recent = LocalProject(
      id: 'recent', name: 'Recente', client: '', address: '', responsible: '',
      notes: '', createdAt: DateTime.utc(2026, 9, 2), updatedAt: DateTime.utc(2026, 9, 2),
    );
    await repository.save(old);
    await repository.save(recent);
    var projects = await repository.getAll();
    expect(projects.map((p) => p.id), ['recent', 'old']);

    await repository.save(old.copyWith(name: 'Antigo editado', updatedAt: DateTime.utc(2026, 9, 3)));
    projects = await repository.getAll();
    expect(projects.first.id, 'old');
    expect(projects.first.name, 'Antigo editado');

    await repository.delete('recent');
    projects = await repository.getAll();
    expect(projects.map((p) => p.id), ['old']);
  });

  test('project repository keeps valid projects beside malformed data', () async {
    final valid = LocalProject(
      id: 'valid',
      name: 'Projeto válido',
      client: '',
      address: '',
      responsible: '',
      notes: '',
      createdAt: DateTime.utc(2026, 9, 30),
      updatedAt: DateTime.utc(2026, 9, 30),
    );
    SharedPreferences.setMockInitialValues({
      'local_projects_v1': jsonEncode([
        valid.toJson(),
        {
          'id': 'broken',
          'name': 'Projeto incompatível',
          'createdAt': 'invalid-date',
          'updatedAt': 'invalid-date',
        },
      ]),
    });

    final projects = await PreferencesProjectRepository().getAll();

    expect(projects.map((p) => p.id), ['valid']);
  });

  test('project repository reorders project after activity update', () async {
    final repository = PreferencesProjectRepository();
    final active = LocalProject(
      id: 'active', name: 'Obra ativa', client: '', address: '', responsible: '',
      notes: '', createdAt: DateTime.utc(2026, 9, 1), updatedAt: DateTime.utc(2026, 9, 1),
    );
    final other = LocalProject(
      id: 'other', name: 'Outra obra', client: '', address: '', responsible: '',
      notes: '', createdAt: DateTime.utc(2026, 9, 2), updatedAt: DateTime.utc(2026, 9, 2),
    );
    await repository.save(active);
    await repository.save(other);
    expect((await repository.getAll()).first.id, 'other');

    await repository.save(active.copyWith(updatedAt: DateTime.utc(2026, 9, 3)));
    expect((await repository.getAll()).first.id, 'active');
  });

  test('technical records are isolated by project and can cascade delete', () async {
    final repository = PreferencesProjectRecordRepository();
    ProjectRecord record(String id, String projectId, DateTime date) => ProjectRecord(
      id: id,
      projectId: projectId,
      type: ProjectRecordType.motor,
      title: 'Motor',
      summary: 'Resumo',
      data: {'currentA': 10.0, 'nested': [{'value': 1}]},
      createdAt: date,
    );

    await repository.save(record('a1', 'a', DateTime.utc(2026, 9, 1)));
    await repository.save(record('b1', 'b', DateTime.utc(2026, 9, 2)));
    await repository.save(record('a2', 'a', DateTime.utc(2026, 9, 3)));

    final a = await repository.getByProject('a');
    expect(a.map((r) => r.id), ['a2', 'a1']);
    expect(a.first.data['currentA'], 10.0);

    await repository.delete('a1');
    expect((await repository.getByProject('a')).map((r) => r.id), ['a2']);
    expect((await repository.getByProject('b')).length, 1);

    await repository.deleteByProject('a');
    expect(await repository.getByProject('a'), isEmpty);
    expect((await repository.getByProject('b')).single.id, 'b1');
  });

  test('record repository keeps valid entries when one stored entry is malformed', () async {
    final valid = ProjectRecord(
      id: 'valid',
      projectId: 'p1',
      type: ProjectRecordType.motor,
      title: 'Motor válido',
      summary: '',
      data: {'currentA': 10.0},
      createdAt: DateTime.utc(2026, 9, 30),
    );
    SharedPreferences.setMockInitialValues({
      'project_records_v1': jsonEncode([
        valid.toJson(),
        {
          'id': 'broken',
          'projectId': 'p1',
          'type': 'removedFutureType',
          'title': 'Registro incompatível',
          'createdAt': 'invalid-date',
        },
      ]),
    });

    final records =
        await PreferencesProjectRecordRepository().getByProject('p1');

    expect(records.map((r) => r.id), ['valid']);
  });

  test('project repositories recover from completely invalid stored JSON', () async {
    SharedPreferences.setMockInitialValues({
      'local_projects_v1': '{invalid-json',
      'project_records_v1': '[also-invalid',
    });

    expect(await PreferencesProjectRepository().getAll(), isEmpty);
    expect(
      await PreferencesProjectRecordRepository().getByProject('p1'),
      isEmpty,
    );
  });

  test('ProjectRecord survives JSON round trip with structured data', () {
    final record = ProjectRecord(
      id: 'r1',
      projectId: 'p1',
      type: ProjectRecordType.loadSurvey,
      title: 'Levantamento',
      summary: '2 cargas',
      data: {
        'installedKw': 6.0,
        'loads': [
          {'description': 'Motor', 'quantity': 1, 'powerFactor': 0.85}
        ],
      },
      createdAt: DateTime.utc(2026, 9, 30),
    );
    final restored = ProjectRecord.fromJson(record.toJson());
    expect(restored.type, ProjectRecordType.loadSurvey);
    expect(restored.projectId, 'p1');
    expect(restored.data['installedKw'], 6.0);
    expect((restored.data['loads'] as List).length, 1);
  });
}
