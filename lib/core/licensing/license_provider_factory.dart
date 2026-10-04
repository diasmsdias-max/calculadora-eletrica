import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'license_provider.dart';
import 'license_provider_diagnostics.dart';
import 'vis_credential_verifier.dart';
import 'vis_license_api.dart';
import 'vis_license_config.dart';
import 'vis_license_provider.dart';

abstract final class LicenseProviderFactory {
  static LicenseProviderDiagnostics lastDiagnostics = _initialDiagnostics();

  static LicenseProvider create() {
    var diagnostics = _initialDiagnostics();
    final configurationFailure = _configurationFailure(diagnostics);
    if (configurationFailure != null) {
      return _fallback(
        diagnostics.copyWith(
          stage: 'configuration',
          fallbackCode: configurationFailure,
        ),
      );
    }

    try {
      diagnostics = diagnostics.copyWith(stage: 'public-key-decode');
      final publicKey = base64Decode(VisLicenseConfig.publicKeyBase64);
      diagnostics = diagnostics.copyWith(
        publicKeyByteLength: publicKey.length,
        stage: 'public-key-validation',
      );
      if (publicKey.length != 32) {
        return _fallback(
          diagnostics.copyWith(fallbackCode: 'public_key_wrong_length'),
        );
      }

      HttpClient Function()? clientFactory;
      if (VisLicenseConfig.usesDevelopmentCa) {
        diagnostics = diagnostics.copyWith(stage: 'ca-decode');
        final certificate = base64Decode(
          VisLicenseConfig.localCaCertificateBase64,
        );
        diagnostics = diagnostics.copyWith(stage: 'ca-installation');
        final context = SecurityContext(withTrustedRoots: true)
          ..setTrustedCertificatesBytes(certificate);
        clientFactory = () => HttpClient(context: context);
      }

      diagnostics = diagnostics.copyWith(stage: 'api-construction');
      final provider = VisLicenseProvider(
        api: VisLicenseApi(
          Uri.parse(VisLicenseConfig.apiBaseUrl),
          clientFactory: clientFactory,
        ),
        verifier: VisCredentialVerifier(
          expectedKeyId: VisLicenseConfig.keyId,
          publicKeyBytes: publicKey,
        ),
      );
      lastDiagnostics = diagnostics.copyWith(stage: 'ready');
      _debugReport(lastDiagnostics);
      return provider;
    } on FormatException {
      final code = diagnostics.stage == 'ca-decode'
          ? 'ca_base64_invalid'
          : diagnostics.stage == 'public-key-decode'
              ? 'public_key_base64_invalid'
              : 'uri_invalid';
      return _fallback(diagnostics.copyWith(fallbackCode: code));
    } on VisLicenseApiException catch (error) {
      return _fallback(
        diagnostics.copyWith(fallbackCode: error.code.toLowerCase()),
      );
    } on TlsException {
      return _fallback(
        diagnostics.copyWith(fallbackCode: 'ca_certificate_rejected'),
      );
    } catch (error) {
      return _fallback(
        diagnostics.copyWith(
          fallbackCode:
              'unexpected_${error.runtimeType.toString().toLowerCase()}',
        ),
      );
    }
  }

  static LicenseProviderDiagnostics _initialDiagnostics() =>
      LicenseProviderDiagnostics(
        apiBaseUrlProvided: VisLicenseConfig.apiBaseUrl.isNotEmpty,
        apiBaseUrlUsesHttps: VisLicenseConfig.apiBaseUrl.startsWith('https://'),
        keyIdProvided: VisLicenseConfig.keyId.isNotEmpty,
        publicKeyProvided: VisLicenseConfig.publicKeyBase64.isNotEmpty,
        publicKeyByteLength: null,
        caCertificateProvided:
            VisLicenseConfig.localCaCertificateBase64.isNotEmpty,
        stage: 'configuration',
        fallbackCode: null,
      );

  static String? _configurationFailure(
    LicenseProviderDiagnostics diagnostics,
  ) {
    if (!diagnostics.apiBaseUrlProvided) return 'api_base_url_missing';
    if (!diagnostics.apiBaseUrlUsesHttps) return 'api_base_url_not_https';
    if (!diagnostics.publicKeyProvided) return 'public_key_missing';
    if (!diagnostics.keyIdProvided) return 'key_id_missing';
    if (!VisLicenseConfig.isConfigured) {
      return 'development_ca_not_allowed_in_product';
    }
    return null;
  }

  static LicenseProvider _fallback(LicenseProviderDiagnostics diagnostics) {
    lastDiagnostics = diagnostics;
    _debugReport(diagnostics);
    return const FreeLicenseProvider();
  }

  static void _debugReport(LicenseProviderDiagnostics diagnostics) {
    if (kDebugMode) {
      debugPrint('EP25 licensing: ${diagnostics.safeSummary}');
    }
  }
}
