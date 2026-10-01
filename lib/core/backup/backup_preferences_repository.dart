import '../settings/module_preferences.dart';
import '../settings/professional_module_preferences.dart';

abstract interface class BackupPreferencesRepository {
  Future<Map<String, dynamic>> export();
  Future<void> restore(Map<String, dynamic> data);
}

class LocalBackupPreferencesRepository implements BackupPreferencesRepository {
  const LocalBackupPreferencesRepository();

  @override
  Future<Map<String, dynamic>> export() async => {
        'visibleHomeModules':
            (await ModulePreferences.loadVisibleModules()).toList()..sort(),
        'professionalModuleVisible':
            await ProfessionalModulePreferences.loadVisible(),
      };

  @override
  Future<void> restore(Map<String, dynamic> data) async {
    final rawModules = data['visibleHomeModules'];
    final professionalVisible = data['professionalModuleVisible'];
    if (rawModules is! List || professionalVisible is! bool) {
      throw const FormatException('Preferências inválidas no backup.');
    }
    final modules = rawModules
        .whereType<String>()
        .where(ModulePreferences.allModuleIds.contains)
        .toSet();
    if (modules.length != rawModules.length) {
      throw const FormatException('Módulo desconhecido nas preferências.');
    }
    await ModulePreferences.saveVisibleModules(modules);
    await ProfessionalModulePreferences.saveVisible(professionalVisible);
  }
}
