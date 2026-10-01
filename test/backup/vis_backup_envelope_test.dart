import 'package:calculadora_eletrica/core/backup/vis_backup_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips a versioned backup with valid integrity', () {
    final backup = VisBackupEnvelope.create(
      createdAt: DateTime.utc(2026, 10, 1, 9),
      appVersion: '1.0.0+1',
      payload: {
        'projects': [
          {'id': 'p1', 'name': 'Obra'},
        ],
        'professionalProfile': {'companyName': 'Boecker'},
      },
    );

    final decoded = VisBackupEnvelope.decode(backup.encode());
    expect(decoded.version, VisBackupEnvelope.currentVersion);
    expect(decoded.appVersion, '1.0.0+1');
    expect(decoded.payload['projects'], isA<List>());
  });

  test('rejects a backup whose payload was modified', () {
    final encoded = VisBackupEnvelope.create(
      createdAt: DateTime.utc(2026, 10, 1, 9),
      appVersion: '1.0.0+1',
      payload: {'projects': const []},
    ).encode();

    final tampered = encoded.replaceFirst(
      '"projects":[]',
      '"projects":[{"id":"tampered"}]',
    );

    expect(
      () => VisBackupEnvelope.decode(tampered),
      throwsA(isA<FormatException>()),
    );
  });

  test('integrity is stable regardless of map key insertion order', () {
    final first = VisBackupEnvelope.create(
      createdAt: DateTime.utc(2026, 10, 1),
      appVersion: '1.0.0+1',
      payload: {'b': 2, 'a': 1},
    );
    final second = VisBackupEnvelope.create(
      createdAt: DateTime.utc(2026, 10, 1),
      appVersion: '1.0.0+1',
      payload: {'a': 1, 'b': 2},
    );

    expect(first.integrity, second.integrity);
  });
}
