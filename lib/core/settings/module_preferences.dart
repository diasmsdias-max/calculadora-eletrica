import 'package:shared_preferences/shared_preferences.dart';

abstract final class ModulePreferences {
  static const _key = 'visible_home_modules';
  static const _knownKey = 'known_home_modules';

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
    if (saved == null) {
      await prefs.setStringList(_knownKey, allModuleIds.toList()..sort());
      return Set<String>.from(allModuleIds);
    }
    final visible = saved.where(allModuleIds.contains).toSet();
    final knownSaved = prefs.getStringList(_knownKey);
    if (knownSaved != null) {
      final newModules = allModuleIds.difference(knownSaved.toSet());
      if (newModules.isNotEmpty) {
        visible.addAll(newModules);
        await prefs.setStringList(_key, visible.toList()..sort());
      }
    }
    await prefs.setStringList(_knownKey, allModuleIds.toList()..sort());
    return visible;
  }

  static Future<void> saveVisibleModules(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final sanitized = ids.where(allModuleIds.contains).toList()..sort();
    await prefs.setStringList(_key, sanitized);
    await prefs.setStringList(_knownKey, allModuleIds.toList()..sort());
  }
}
