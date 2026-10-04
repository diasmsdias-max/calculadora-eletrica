class LicenseProviderDiagnostics {
  final bool apiBaseUrlProvided;
  final bool apiBaseUrlUsesHttps;
  final bool keyIdProvided;
  final bool publicKeyProvided;
  final int? publicKeyByteLength;
  final bool caCertificateProvided;
  final String stage;
  final String? fallbackCode;

  const LicenseProviderDiagnostics({
    required this.apiBaseUrlProvided,
    required this.apiBaseUrlUsesHttps,
    required this.keyIdProvided,
    required this.publicKeyProvided,
    required this.publicKeyByteLength,
    required this.caCertificateProvided,
    required this.stage,
    required this.fallbackCode,
  });

  bool get isReady => fallbackCode == null && stage == 'ready';

  LicenseProviderDiagnostics copyWith({
    int? publicKeyByteLength,
    String? stage,
    String? fallbackCode,
  }) =>
      LicenseProviderDiagnostics(
        apiBaseUrlProvided: apiBaseUrlProvided,
        apiBaseUrlUsesHttps: apiBaseUrlUsesHttps,
        keyIdProvided: keyIdProvided,
        publicKeyProvided: publicKeyProvided,
        publicKeyByteLength: publicKeyByteLength ?? this.publicKeyByteLength,
        caCertificateProvided: caCertificateProvided,
        stage: stage ?? this.stage,
        fallbackCode: fallbackCode ?? this.fallbackCode,
      );

  String get safeSummary => <String>[
        'apiBaseUrl=${apiBaseUrlProvided ? 'presente' : 'ausente'}',
        'https=${apiBaseUrlUsesHttps ? 'sim' : 'nao'}',
        'keyId=${keyIdProvided ? 'presente' : 'ausente'}',
        'publicKey=${publicKeyProvided ? 'presente' : 'ausente'}',
        'publicKeyBytes=${publicKeyByteLength?.toString() ?? 'nao-decodificada'}',
        'ca=${caCertificateProvided ? 'presente' : 'ausente'}',
        'etapa=$stage',
        'fallback=${fallbackCode ?? 'nenhum'}',
      ].join('; ');
}
