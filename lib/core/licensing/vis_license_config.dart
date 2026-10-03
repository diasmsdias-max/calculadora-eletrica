abstract final class VisLicenseConfig {
  static const apiBaseUrl = String.fromEnvironment('VIS_LICENSE_API_BASE_URL');
  static const keyId = String.fromEnvironment(
    'VIS_LICENSE_KEY_ID',
    defaultValue: 'vis-license-signing-1',
  );
  static const publicKeyBase64 =
      String.fromEnvironment('VIS_LICENSE_PUBLIC_KEY_BASE64');

  static bool get isConfigured =>
      apiBaseUrl.startsWith('https://') &&
      publicKeyBase64.isNotEmpty &&
      keyId.isNotEmpty;
}
