import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calculadora_eletrica/core/backup/backup_preferences_repository.dart';
import 'package:calculadora_eletrica/core/backup/vis_backup_restore_coordinator.dart';
import 'package:calculadora_eletrica/core/backup/vis_backup_service.dart';
import 'package:calculadora_eletrica/core/database/vis_database.dart';
import 'package:calculadora_eletrica/core/professional/professional_profile.dart';
import 'package:calculadora_eletrica/core/professional/professional_profile_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await VisDatabase.createSchemaForTesting(db);
  });

  tearDown(() => db.close());

  test('profile failure restores previous database and profile', () async {
    final service = VisBackupService(db);
    final profileRepository = _FailOnceProfileRepository(
      const ProfessionalProfile(companyName: 'Empresa local'),
    );

    await db.insert('projects', _project('backup', 'Projeto backup'));
    final source = await service.createBackup(
      appVersion: 'test',
      professionalProfile: const ProfessionalProfile(
        companyName: 'Empresa backup',
      ).toJson().cast<String, dynamic>(),
    );

    await db.delete('projects');
    await db.insert('projects', _project('local', 'Projeto local'));

    await expectLater(
      VisBackupRestoreCoordinator(
        backupService: service,
        profileRepository: profileRepository,
      ).restore(source),
      throwsA(isA<StateError>()),
    );

    final projects = await db.query('projects');
    expect(projects.single['id'], 'local');
    expect((await profileRepository.load())!.companyName, 'Empresa local');
  });
  test('invalid preferences are rejected before database replacement', () async {
    final service = VisBackupService(db);
    final profileRepository = _FailOnceProfileRepository(null)
      ..failNextWrite = false;
    final preferences = _FakePreferencesRepository();

    await db.insert('projects', _project('backup', 'Projeto backup'));
    final source = await service.createBackup(
      appVersion: 'test',
      preferences: {
        'visibleHomeModules': ['unknown-module'],
        'professionalModuleVisible': true,
      },
    );

    await db.delete('projects');
    await db.insert('projects', _project('local', 'Projeto local'));

    await expectLater(
      VisBackupRestoreCoordinator(
        backupService: service,
        profileRepository: profileRepository,
        preferencesRepository: preferences,
      ).restore(source),
      throwsA(isA<FormatException>()),
    );

    final projects = await db.query('projects');
    expect(projects.single['id'], 'local');
    expect(preferences.restoreCalls, 0);
  });

}

class _FailOnceProfileRepository implements ProfessionalProfileRepository {
  ProfessionalProfile? value;
  bool failNextWrite = true;

  _FailOnceProfileRepository(this.value);

  @override
  Future<ProfessionalProfile?> load() async => value;

  @override
  Future<void> save(ProfessionalProfile profile) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Falha simulada');
    }
    value = profile;
  }

  @override
  Future<void> clear() async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Falha simulada');
    }
    value = null;
  }
}

Map<String, Object?> _project(String id, String name) => {
      'id': id,
      'name': name,
      'client': '',
      'address': '',
      'responsible': '',
      'notes': '',
      'created_at': DateTime.utc(2026, 10, 1).toIso8601String(),
      'updated_at': DateTime.utc(2026, 10, 1).toIso8601String(),
    };

class _FakePreferencesRepository implements BackupPreferencesRepository {
  int restoreCalls = 0;

  @override
  Future<Map<String, dynamic>> export() async => {
        'visibleHomeModules': ['motor'],
        'professionalModuleVisible': true,
      };

  @override
  void validate(Map<String, dynamic> data) {
    final modules = data['visibleHomeModules'];
    if (modules is! List || modules.any((item) => item == 'unknown-module')) {
      throw const FormatException('Preferências inválidas no backup.');
    }
  }

  @override
  Future<void> restore(Map<String, dynamic> data) async {
    validate(data);
    restoreCalls++;
  }
}
