import 'dart:io';

import 'package:calculadora_eletrica/core/technical_center/local_technical_document_file_store.dart';
import 'package:calculadora_eletrica/core/technical_center/technical_document_checksum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores and removes document below injected base directory', () async {
    final base = await Directory.systemTemp.createTemp('vis_technical_');
    addTearDown(() => base.delete(recursive: true));

    final store = LocalTechnicalDocumentFileStore(base);
    final path = await store.write(
      documentId: 'weg-cfw500',
      fileName: 'manual.pdf',
      bytes: [1, 2, 3],
    );

    expect(path, contains('technical_documents'));
    expect(await store.exists(path), isTrue);

    await store.delete(path);
    expect(await store.exists(path), isFalse);
  });

  test('sanitizes document id and strips path traversal from file name', () async {
    final base = await Directory.systemTemp.createTemp('vis_technical_');
    addTearDown(() => base.delete(recursive: true));

    final store = LocalTechnicalDocumentFileStore(base);
    final path = await store.write(
      documentId: 'WEG CFW/500',
      fileName: '../../manual.pdf',
      bytes: [1],
    );

    expect(path, contains('WEG_CFW_500'));
    expect(path, endsWith('manual.pdf'));
    expect(path, isNot(contains('..')));
  });

  test('calculates known SHA-256 digest', () {
    expect(
      technicalDocumentSha256([97, 98, 99]),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
