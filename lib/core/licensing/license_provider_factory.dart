import 'dart:convert';

import 'license_provider.dart';
import 'license_state.dart';
import 'vis_credential_verifier.dart';
import 'vis_license_api.dart';
import 'vis_license_config.dart';
import 'vis_license_provider.dart';

abstract final class LicenseProviderFactory {
  static LicenseProvider create() {
    if (!VisLicenseConfig.isConfigured) return const FreeLicenseProvider();
    try {
      final publicKey = base64Decode(VisLicenseConfig.publicKeyBase64);
      if (publicKey.length != 32) return const FreeLicenseProvider();
      return VisLicenseProvider(
        api: VisLicenseApi(Uri.parse(VisLicenseConfig.apiBaseUrl)),
        verifier: VisCredentialVerifier(
          expectedKeyId: VisLicenseConfig.keyId,
          publicKeyBytes: publicKey,
        ),
      );
    } catch (_) {
      return const FreeLicenseProvider();
    }
  }
}
