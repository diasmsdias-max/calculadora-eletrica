import 'package:shared_preferences/shared_preferences.dart';

abstract final class ModulePreferences {
  static const _key = 'visible_home_modules';

  static const allModuleIds = <String>{
    'motor',
    'transformer',
    'motorTransformer',
    'loadSurvey',
    'cableSizing',
    'voltageDrop',
  };

  static Future<Set<String>> loadVisibleModules() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (saved == null) return Set<String>.from(allModuleIds);
    return saved.where(allModuleIds.contains).toSet();
  }

  static Future<void> saveVisibleModules(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final sanitized = ids.where(allModuleIds.contains).toList()..sort();
    await prefs.setStringList(_key, sanitized);
  }
}
