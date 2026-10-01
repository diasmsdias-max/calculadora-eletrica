import 'package:calculadora_eletrica/core/licensing/license_provider_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('debug provider starts free and can activate professional entitlement',
      () async {
    const provider = DebugLicenseProvider();

    expect((await provider.currentState()).hasProfessional, isFalse);

    final activated = await provider.activate();
    expect(activated.hasProfessional, isTrue);
    expect((await provider.currentState()).hasProfessional, isTrue);
  });

  test('debug provider can deactivate test entitlement', () async {
    const provider = DebugLicenseProvider();
    await provider.activate();

    final deactivated = await provider.deactivate();

    expect(deactivated.hasProfessional, isFalse);
    expect((await provider.currentState()).hasProfessional, isFalse);
  });
}
