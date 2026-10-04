import 'package:calculadora_eletrica/core/technical_center/http_technical_document_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requires HTTPS base URI for requests', () async {
    final source = HttpTechnicalDocumentSource(
      baseUri: Uri.parse('http://example.invalid/'),
    );

    expect(source.fetchCatalog, throwsArgumentError);
  });

  test('rejects absolute remote document path outside configured host', () async {
    final source = HttpTechnicalDocumentSource(
      baseUri: Uri.parse('https://example.invalid/'),
    );

    expect(
      () => source.download('https://other.example/manual.pdf'),
      throwsArgumentError,
    );
  });

  test('rejects paths that escape configured VIS server root', () async {
    final source = HttpTechnicalDocumentSource(
      baseUri: Uri.parse('https://example.invalid/vis/'),
    );

    expect(
      () => source.download('../manual.pdf'),
      throwsArgumentError,
    );
    expect(
      () => source.download('/manual.pdf'),
      throwsArgumentError,
    );
  });

}
