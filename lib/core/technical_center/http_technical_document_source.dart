import 'dart:convert';
import 'dart:io';

import 'technical_document.dart';
import 'technical_document_catalog_sync_service.dart';
import 'technical_document_offline_service.dart';

class HttpTechnicalDocumentSource
    implements TechnicalDocumentCatalogSource, TechnicalDocumentRemoteSource {
  final Uri baseUri;
  final String catalogPath;
  final Duration timeout;
  final HttpClient Function() clientFactory;

  HttpTechnicalDocumentSource({
    required this.baseUri,
    this.catalogPath = 'technical-documents/catalog.json',
    this.timeout = const Duration(seconds: 20),
    HttpClient Function()? clientFactory,
  }) : clientFactory = clientFactory ?? HttpClient.new;

  @override
  Future<List<TechnicalDocument>> fetchCatalog() async {
    final bytes = await _get(_resolve(catalogPath));
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! List) {
      throw const FormatException('Technical document catalog must be a list.');
    }

    return decoded.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Invalid technical document catalog entry.');
      }
      return TechnicalDocument.fromPortableJson(
        Map<String, Object?>.from(entry),
      );
    }).toList();
  }

  @override
  Future<List<int>> download(String remotePath) => _get(_resolve(remotePath));

  Uri _resolve(String path) {
    final candidate = Uri.parse(path);
    if (candidate.hasScheme) {
      if (candidate.scheme != 'https') {
        throw ArgumentError.value(path, 'path', 'Only HTTPS is allowed.');
      }
      return candidate;
    }
    return baseUri.resolve(path);
  }

  Future<List<int>> _get(Uri uri) async {
    if (uri.scheme != 'https') {
      throw ArgumentError.value(uri, 'uri', 'Only HTTPS is allowed.');
    }

    final client = clientFactory();
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      final response = await request.close().timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw HttpException(
          'Technical document request failed with status '
          '${response.statusCode}.',
          uri: uri,
        );
      }
      return await response.fold<List<int>>(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      ).timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}
