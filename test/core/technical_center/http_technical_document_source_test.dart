import 'package:calculadora_eletrica/core/technical_center/http_technical_document_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires HTTPS base URI for requests', () async {
    final source = HttpTechnicalDocumentSource(
      baseUri: Uri.parse('http://example.invalid/'),
    );

    expect(source.fetchCatalog, throwsArgumentError);
  });

  test('rejects explicit non-HTTPS remote document path', () async {
    final source = HttpTechnicalDocumentSource(
      baseUri: Uri.parse('https://example.invalid/'),
    );

    expect(
      () => source.download('http://example.invalid/manual.pdf'),
      throwsArgumentError,
    );
  });
}
