class TechnicalCenterConfig {
  static const _baseUrl = String.fromEnvironment(
    'VIS_TECHNICAL_CENTER_BASE_URL',
  );

  const TechnicalCenterConfig._();

  static Uri? get baseUri {
    final value = _baseUrl.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != 'https' || uri.host.isEmpty) {
      return null;
    }
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }
}
