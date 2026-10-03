import 'dart:async';
import 'dart:convert';
import 'dart:io';

class VisLicenseApi {
  final Uri baseUri;
  final Duration timeout;
  final HttpClient Function() clientFactory;

  VisLicenseApi(
    Uri baseUri, {
    this.timeout = const Duration(seconds: 20),
    HttpClient Function()? clientFactory,
  })  : baseUri = _validatedBaseUri(baseUri),
        clientFactory = clientFactory ?? HttpClient.new;

  static Uri _validatedBaseUri(Uri uri) {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const VisLicenseApiException('INVALID_BASE_URL');
    }
    final normalizedPath = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: normalizedPath);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    if (endpoint.isEmpty ||
        endpoint.startsWith('/') ||
        endpoint.contains('..') ||
        Uri.tryParse(endpoint)?.hasScheme == true) {
      throw const VisLicenseApiException('INVALID_ENDPOINT');
    }

    final client = clientFactory()..connectionTimeout = timeout;
    try {
      final uri = baseUri.resolve(endpoint);
      if (uri.scheme != baseUri.scheme ||
          uri.host != baseUri.host ||
          uri.port != baseUri.port ||
          !uri.path.startsWith(baseUri.path)) {
        throw const VisLicenseApiException('INVALID_ENDPOINT');
      }

      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.write(jsonEncode(body));

      final response = await request.close().timeout(timeout);
      final raw = await utf8.decoder.bind(response).join().timeout(timeout);

      Map<String, dynamic> decoded;
      try {
        final value = jsonDecode(raw);
        if (value is! Map<String, dynamic>) {
          throw const VisLicenseApiException('INVALID_RESPONSE');
        }
        decoded = value;
      } on FormatException {
        throw const VisLicenseApiException('INVALID_RESPONSE');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        final code = error is Map ? error['code']?.toString() : null;
        throw VisLicenseApiException(code ?? 'SERVER_ERROR');
      }
      return decoded;
    } on VisLicenseApiException {
      rethrow;
    } on SocketException {
      throw const VisLicenseApiException('NETWORK_ERROR');
    } on HandshakeException {
      throw const VisLicenseApiException('TLS_ERROR');
    } on HttpException {
      throw const VisLicenseApiException('NETWORK_ERROR');
    } on TimeoutException {
      throw const VisLicenseApiException('NETWORK_ERROR');
    } finally {
      client.close(force: true);
    }
  }
}

class VisLicenseApiException implements Exception {
  final String code;
  const VisLicenseApiException(this.code);
}
