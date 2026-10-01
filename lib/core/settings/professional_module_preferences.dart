import 'package:shared_preferences/shared_preferences.dart';

abstract final class ProfessionalModulePreferences {
  static const _visibleKey = 'professional_module_visible';

  static Future<bool> loadVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_visibleKey) ?? true;
  }

  static Future<void> saveVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visibleKey, visible);
  }
}
