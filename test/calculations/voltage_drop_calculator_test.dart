import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/voltage_drop_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoltageDropCalculator', () {
    test('cobre monofásico calcula queda e percentual', () {
      final r = VoltageDropCalculator.calculate(
        system: AcSystem.singlePhase,
        voltageV: 220,
        currentA: 20,
        lengthM: 30,
        sectionMm2: 4,
        material: ConductorMaterial.copper,
        powerFactor: 1,
        maxDropPercent: 4,
      );
      expect(r.dropV, closeTo(5.25, 0.001));
      expect(r.dropPercent, closeTo(2.386, 0.01));
      expect(r.withinLimit, isTrue);
    });

    test('trifásico calcula seção mínima por limite de queda', () {
      final r = VoltageDropCalculator.calculate(
        system: AcSystem.threePhase,
        voltageV: 380,
        currentA: 50,
        lengthM: 100,
        sectionMm2: 10,
        material: ConductorMaterial.copper,
        powerFactor: 0.9,
        maxDropPercent: 4,
      );
      expect(r.minimumSectionMm2, greaterThan(8));
      expect(r.commercialSectionMm2, 10);
    });

    test('reatância opcional aumenta a queda com fator de potência menor que 1', () {
      final resistiveOnly = VoltageDropCalculator.calculate(
        system: AcSystem.threePhase,
        voltageV: 380,
        currentA: 80,
        lengthM: 100,
        sectionMm2: 25,
        material: ConductorMaterial.copper,
        powerFactor: 0.8,
        maxDropPercent: 4,
      );
      final withReactance = VoltageDropCalculator.calculate(
        system: AcSystem.threePhase,
        voltageV: 380,
        currentA: 80,
        lengthM: 100,
        sectionMm2: 25,
        material: ConductorMaterial.copper,
        powerFactor: 0.8,
        maxDropPercent: 4,
        reactanceOhmPerKm: 0.08,
      );
      expect(withReactance.dropV, greaterThan(resistiveOnly.dropV));
    });

    test('alumínio apresenta maior queda que cobre na mesma seção', () {
      final copper = VoltageDropCalculator.calculate(
        system: AcSystem.twoPhase,
        voltageV: 220,
        currentA: 30,
        lengthM: 40,
        sectionMm2: 6,
        material: ConductorMaterial.copper,
        powerFactor: 0.9,
        maxDropPercent: 4,
      );
      final aluminum = VoltageDropCalculator.calculate(
        system: AcSystem.twoPhase,
        voltageV: 220,
        currentA: 30,
        lengthM: 40,
        sectionMm2: 6,
        material: ConductorMaterial.aluminum,
        powerFactor: 0.9,
        maxDropPercent: 4,
      );
      expect(aluminum.dropV, greaterThan(copper.dropV));
    });
  });
}
