import 'package:calculadora_eletrica/core/calculations/conductor_check_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/voltage_drop_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConductorCheckCalculator', () {
    test('aprova somente quando ampacidade e queda atendem', () {
      final r = ConductorCheckCalculator.calculate(
        system: AcSystem.twoPhase,
        voltageV: 220,
        designCurrentA: 20,
        lengthM: 30,
        sectionMm2: 4,
        material: ConductorMaterial.copper,
        powerFactor: 1,
        maxDropPercent: 4,
        temperatureFactor: 1,
        groupingFactor: 1,
        referenceAmpacityA: 28,
      );
      expect(r.ampacityMeets, isTrue);
      expect(r.voltageDrop.withinLimit, isTrue);
      expect(r.meetsBothCriteria, isTrue);
    });

    test('reprova se ampacidade corrigida não atende', () {
      final r = ConductorCheckCalculator.calculate(
        system: AcSystem.twoPhase,
        voltageV: 220,
        designCurrentA: 20,
        lengthM: 20,
        sectionMm2: 6,
        material: ConductorMaterial.copper,
        powerFactor: 1,
        maxDropPercent: 4,
        temperatureFactor: 0.8,
        groupingFactor: 0.8,
        referenceAmpacityA: 25,
      );
      expect(r.ampacityMeets, isFalse);
      expect(r.voltageDrop.withinLimit, isTrue);
      expect(r.meetsBothCriteria, isFalse);
    });

    test('reprova se queda excede o limite', () {
      final r = ConductorCheckCalculator.calculate(
        system: AcSystem.twoPhase,
        voltageV: 220,
        designCurrentA: 30,
        lengthM: 100,
        sectionMm2: 4,
        material: ConductorMaterial.copper,
        powerFactor: 1,
        maxDropPercent: 4,
        temperatureFactor: 1,
        groupingFactor: 1,
        referenceAmpacityA: 40,
      );
      expect(r.ampacityMeets, isTrue);
      expect(r.voltageDrop.withinLimit, isFalse);
      expect(r.meetsBothCriteria, isFalse);
    });
  });
}
