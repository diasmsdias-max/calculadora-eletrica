import 'package:calculadora_eletrica/core/settings/professional_module_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('professional module is visible by default', () async {
    expect(await ProfessionalModulePreferences.loadVisible(), isTrue);
  });

  test('professional module visibility is persisted independently', () async {
    await ProfessionalModulePreferences.saveVisible(false);

    expect(await ProfessionalModulePreferences.loadVisible(), isFalse);
  });
}
