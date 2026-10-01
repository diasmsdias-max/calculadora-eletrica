import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/transformer_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransformerCalculator', () {
    test('transformador trifásico 10 kVA 220 V fornece cerca de 26,24 A', () {
      final result = TransformerCalculator.calculate(
        ratedKva: 10,
        system: AcSystem.threePhase,
        voltageV: 220,
        loadPowerFactor: 0.8,
      );
      expect(result.availableCurrentA, closeTo(26.24, 0.02));
      expect(result.availableActivePowerKw, closeTo(8, 0.001));
    });

    test('converte carga ativa para kVA e calcula carregamento', () {
      final result = TransformerCalculator.calculate(
        ratedKva: 30,
        system: AcSystem.threePhase,
        voltageV: 380,
        loadPowerFactor: 0.9,
        loadKw: 18,
      );
      expect(result.loadKva, closeTo(20, 0.001));
      expect(result.loadPercent, closeTo(66.6667, 0.01));
      expect(result.remainingKva, closeTo(10, 0.001));
      expect(result.meetsLoad, isTrue);
    });

    test('identifica sobrecarga em regime permanente', () {
      final result = TransformerCalculator.calculate(
        ratedKva: 10,
        system: AcSystem.twoPhase,
        voltageV: 220,
        loadPowerFactor: 0.85,
        loadKva: 12,
      );
      expect(result.loadPercent, closeTo(120, 0.001));
      expect(result.remainingKva, 0);
      expect(result.meetsLoad, isFalse);
    });
  });
}
