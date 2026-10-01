import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'license_provider.dart';
import 'license_state.dart';

abstract final class LicenseProviderFactory {
  static LicenseProvider create() =>
      kDebugMode ? const DebugLicenseProvider() : const FreeLicenseProvider();
}

class DebugLicenseProvider implements LicenseProvider {
  static const _activeKey = 'debug_professional_license_active';

  const DebugLicenseProvider();

  @override
  Future<LicenseState> currentState() async {
    final prefs = await SharedPreferences.getInstance();
    return _state(prefs.getBool(_activeKey) ?? false);
  }

  @override
  Future<LicenseState> activate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, true);
    return _state(true);
  }

  Future<LicenseState> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activeKey, false);
    return _state(false);
  }

  @override
  Future<LicenseState> revalidate() => currentState();

  LicenseState _state(bool active) => LicenseState(
        status: active ? LicenseStatus.active : LicenseStatus.free,
        entitlements:
            active ? const {Entitlement.professional} : const <Entitlement>{},
      );
}
