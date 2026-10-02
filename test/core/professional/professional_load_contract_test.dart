import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora_eletrica/core/professional/professional_load.dart';

void main() {
  final now = DateTime.utc(2026, 10, 2);

  test('professional load v2 portable round trip preserves FS metadata', () {
    final load = ProfessionalLoad(
      id: 'l1',
      projectId: 'p1',
      revision: 2,
      name: 'Motores',
      quantity: 4,
      powerW: 10000,
      voltageV: 220,
      simultaneityFactor: 0.7,
      simultaneitySource: 'visEstimate',
      simultaneityBasis: 'Demanda simultânea informada.',
      createdAt: now,
      updatedAt: now,
    );

    final restored = ProfessionalLoad.fromPortableJson(load.toPortableJson());
    expect(restored.simultaneityFactor, 0.7);
    expect(restored.simultaneitySource, 'visEstimate');
    expect(restored.simultaneityBasis, 'Demanda simultânea informada.');
  });

  test('professional load v1 remains readable without assuming FS', () {
    final restored = ProfessionalLoad.fromPortableJson({
      'contractVersion': 1,
      'id': 'legacy',
      'projectId': 'p1',
      'revision': 1,
      'name': 'Carga antiga',
      'category': '',
      'quantity': 1,
      'powerW': 1000,
      'voltageV': 220,
      'powerFactor': null,
      'notes': '',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    expect(restored.simultaneityFactor, isNull);
    expect(restored.simultaneitySource, isNull);
    expect(restored.simultaneityBasis, isEmpty);
  });
}
