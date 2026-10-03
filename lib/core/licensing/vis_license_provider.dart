import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'installation_identity.dart';
import 'license_provider.dart';
import 'license_state.dart';
import 'vis_credential_verifier.dart';
import 'vis_license_api.dart';

class VisLicenseProvider implements LicenseProvider {
  static const _credentialKey = 'vis_license_credential';
  static const _licenseIdKey = 'vis_license_id';

  final VisLicenseApi api;
  final VisCredentialVerifier verifier;
  final InstallationIdentity identity;

  const VisLicenseProvider({
    required this.api,
    required this.verifier,
    this.identity = const InstallationIdentity(),
  });

  @override
  Future<LicenseState> currentState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_credentialKey);
    if (raw == null) return const LicenseState();
    try {
      final credential = jsonDecode(raw);
      if (credential is! Map<String, dynamic>) return const LicenseState();
      final installationId = await identity.getOrCreate();
      final verified = await verifier.verify(
        credential: credential,
        installationId: installationId,
      );
      if (verified == null) return const LicenseState(status: LicenseStatus.inactive);
      if (!verified.isOfflineValid) {
        return const LicenseState(status: LicenseStatus.validationRequired);
      }
      return _activeState(verified.permissions);
    } catch (_) {
      return const LicenseState(status: LicenseStatus.inactive);
    }
  }

  @override
  Future<LicenseState> activate([String? activationKey]) async {
    final key = activationKey?.trim();
    if (key == null || key.isEmpty) return const LicenseState();
    final installationId = await identity.getOrCreate();
    final response = await api.post('activate', {
      'contractVersion': 1,
      'activationKey': key,
      'installationId': installationId,
    });
    return _acceptServerResponse(response, installationId);
  }

  @override
  Future<LicenseState> revalidate() async {
    final prefs = await SharedPreferences.getInstance();
    final licenseId = prefs.getString(_licenseIdKey);
    if (licenseId == null) return const LicenseState();
    final installationId = await identity.getOrCreate();
    final response = await api.post('refresh', {
      'contractVersion': 1,
      'licenseId': licenseId,
      'installationId': installationId,
    });
    return _acceptServerResponse(response, installationId);
  }

  Future<LicenseState> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    final licenseId = prefs.getString(_licenseIdKey);
    if (licenseId != null) {
      final installationId = await identity.getOrCreate();
      await api.post('deactivate', {
        'contractVersion': 1,
        'licenseId': licenseId,
        'installationId': installationId,
      });
    }
    await prefs.remove(_credentialKey);
    await prefs.remove(_licenseIdKey);
    return const LicenseState();
  }

  Future<LicenseState> _acceptServerResponse(
    Map<String, dynamic> response,
    String installationId,
  ) async {
    final rawCredential = response['credential'];
    if (rawCredential is! Map) {
      return const LicenseState(status: LicenseStatus.inactive);
    }
    final credential = Map<String, dynamic>.from(rawCredential);
    final verified = await verifier.verify(
      credential: credential,
      installationId: installationId,
    );
    if (verified == null || !verified.isOfflineValid) {
      return const LicenseState(status: LicenseStatus.inactive);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_credentialKey, jsonEncode(credential));
    await prefs.setString(_licenseIdKey, verified.licenseId);
    return _activeState(verified.permissions);
  }

  LicenseState _activeState(Set<String> permissions) => LicenseState(
        status: LicenseStatus.active,
        entitlements: permissions.contains('professional')
            ? const {Entitlement.professional}
            : const <Entitlement>{},
      );
}
