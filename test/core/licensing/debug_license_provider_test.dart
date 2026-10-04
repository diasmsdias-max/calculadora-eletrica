import 'package:calculadora_eletrica/core/licensing/license_provider.dart';
import 'package:calculadora_eletrica/core/licensing/license_provider_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factory falls back to free provider when licensing is not configured', () async {
    final provider = LicenseProviderFactory.create();

    expect(provider, isA<FreeLicenseProvider>());
    expect((await provider.currentState()).hasProfessional, isFalse);
  });

  test('free provider never grants professional entitlement from an activation key', () async {
    const provider = FreeLicenseProvider();

    final activated = await provider.activate('VIS-PRO-TEST-KEY');

    expect(activated.hasProfessional, isFalse);
    expect((await provider.currentState()).hasProfessional, isFalse);
  });
}
