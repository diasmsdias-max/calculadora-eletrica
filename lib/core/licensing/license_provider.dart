import 'license_state.dart';

abstract interface class LicenseProvider {
  Future<LicenseState> currentState();

  Future<LicenseState> activate([String? activationKey]);

  Future<LicenseState> revalidate();
}

class FreeLicenseProvider implements LicenseProvider {
  const FreeLicenseProvider();

  @override
  Future<LicenseState> currentState() async => const LicenseState();

  @override
  Future<LicenseState> activate([String? activationKey]) async => const LicenseState();

  @override
  Future<LicenseState> revalidate() async => const LicenseState();
}
