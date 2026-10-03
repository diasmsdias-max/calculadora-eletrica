import 'dart:convert';
import 'dart:io';

class VisLicenseApi {
  final Uri baseUri;
  const VisLicenseApi(this.baseUri);

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final client = HttpClient();
    try {
      final uri = baseUri.resolve(endpoint);
      if (uri.scheme != 'https' || uri.host != baseUri.host) {
        throw const VisLicenseApiException('INVALID_ENDPOINT');
      }
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      final raw = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const VisLicenseApiException('INVALID_RESPONSE');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        final code = error is Map ? error['code']?.toString() : null;
        throw VisLicenseApiException(code ?? 'SERVER_ERROR');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }
}

class VisLicenseApiException implements Exception {
  final String code;
  const VisLicenseApiException(this.code);
}
