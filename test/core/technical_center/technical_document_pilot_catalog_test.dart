import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document.dart';

void main() {
  test('VIS manual pilot catalog follows technical document contract', () async {
    final raw = await File(
      'test/fixtures/technical_documents/catalog.json',
    ).readAsString();
    final decoded = jsonDecode(raw) as List<dynamic>;

    expect(decoded, hasLength(1));
    final document = TechnicalDocument.fromPortableJson(
      Map<String, Object?>.from(decoded.single as Map),
    );

    expect(document.id, 'vis-manual-vis-electrica');
    expect(document.title, 'Manual do VIS ELECTRICA');
    expect(document.category, TechnicalDocumentCategory.technicalReference);
    expect(document.mimeType, 'application/pdf');
    expect(document.fileName, 'Manual_VIS_ELECTRICA.pdf');
    expect(document.sizeBytes, 36872);
    expect(
      document.checksum,
      '7d54aa4e53bafcf840f3820cc22c87e3b7f39e5627e2e1b9fa0e1d74689abe80',
    );
    expect(document.availability, TechnicalDocumentAvailability.remoteOnly);
    expect(document.remotePath, isNotEmpty);
    expect(document.localPath, isNull);
  });
}
