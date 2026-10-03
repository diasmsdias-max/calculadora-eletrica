import 'dart:io';
import 'dart:convert';

import 'license_provider.dart';
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
      HttpClient Function()? clientFactory;
      if (VisLicenseConfig.usesDevelopmentCa) {
        final certificate = base64Decode(
          VisLicenseConfig.localCaCertificateBase64,
        );
        final context = SecurityContext(withTrustedRoots: true)
          ..setTrustedCertificatesBytes(certificate);
        clientFactory = () => HttpClient(context: context);
      }
      return VisLicenseProvider(
        api: VisLicenseApi(
          Uri.parse(VisLicenseConfig.apiBaseUrl),
          clientFactory: clientFactory,
        ),
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
