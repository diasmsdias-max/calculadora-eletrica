import 'package:calculadora_eletrica/core/calculations/cable_sizing_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CableSizingCalculator', () {
    test('calcula Iz mínima com fatores de correção', () {
      final r = CableSizingCalculator.calculate(
        designCurrentA: 40,
        temperatureFactor: 0.87,
        groupingFactor: 0.8,
      );
      expect(r.combinedCorrectionFactor, closeTo(0.696, 0.0001));
      expect(r.requiredAmpacityA, closeTo(57.47, 0.01));
    });

    test('verifica capacidade corrigida do cabo informado', () {
      final r = CableSizingCalculator.calculate(
        designCurrentA: 40,
        temperatureFactor: 0.87,
        groupingFactor: 0.8,
      );
      expect(r.correctedAmpacity(60), closeTo(41.76, 0.01));
      expect(r.cableMeets(60), isTrue);
      expect(r.cableMeets(50), isFalse);
    });

    test('rejeita fator de correção inválido', () {
      expect(
        () => CableSizingCalculator.calculate(
          designCurrentA: 20,
          temperatureFactor: 0,
          groupingFactor: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
