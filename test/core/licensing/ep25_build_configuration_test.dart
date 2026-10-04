import 'package:calculadora_eletrica/core/licensing/license_provider_factory.dart';
import 'package:calculadora_eletrica/core/licensing/vis_license_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const _validateEp25Build =
    bool.fromEnvironment('EP25_VALIDATE_BUILD_CONFIGURATION');

void main() {
  test(
    'EP25 dart-defines create the configured VIS provider',
    () {
      final provider = LicenseProviderFactory.create();
      final diagnostics = LicenseProviderFactory.lastDiagnostics;

      expect(
        provider,
        isA<VisLicenseProvider>(),
        reason: diagnostics.safeSummary,
      );
      expect(diagnostics.isReady, isTrue, reason: diagnostics.safeSummary);
    },
    skip: !_validateEp25Build
        ? 'Executado apenas pelo build_ep25_test_apk.ps1.'
        : false,
  );
}
