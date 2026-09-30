import 'package:calculadora_eletrica/core/calculations/motor_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/motor_transformer_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MotorTransformerCalculator', () {
    test('10 kVA não atende motor 15 CV 220 V em regime permanente', () {
      final result = MotorTransformerCalculator.calculate(
        transformerKva: 10,
        motorRatedPower: 15,
        motorUnit: MotorPowerUnit.cv,
        system: AcSystem.threePhase,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.90,
        startingMethod: MotorStartingMethod.direct,
        startingMultiplier: 6,
      );
      expect(result.motor.apparentPowerKva, closeTo(14.42, 0.02));
      expect(result.transformer.meetsLoad, isFalse);
      expect(result.motorTransformerPercent, closeTo(144.22, 0.1));
      expect(result.startingKvaEstimate, closeTo(result.motor.apparentPowerKva * 6, 0.01));
    });

    test('30 kVA atende motor 15 CV em regime permanente', () {
      final result = MotorTransformerCalculator.calculate(
        transformerKva: 30,
        motorRatedPower: 15,
        motorUnit: MotorPowerUnit.cv,
        system: AcSystem.threePhase,
        voltageV: 380,
        powerFactor: 0.85,
        efficiency: 0.90,
      );
      expect(result.transformer.meetsLoad, isTrue);
      expect(result.transformer.remainingKva, greaterThan(15));
    });
    test('multiplicador de partida altera somente a estimativa de partida', () {
      final direct = MotorTransformerCalculator.calculate(
        transformerKva: 30,
        motorRatedPower: 15,
        motorUnit: MotorPowerUnit.cv,
        system: AcSystem.threePhase,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.90,
        startingMultiplier: 6,
      );
      final reduced = MotorTransformerCalculator.calculate(
        transformerKva: 30,
        motorRatedPower: 15,
        motorUnit: MotorPowerUnit.cv,
        system: AcSystem.threePhase,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.90,
        startingMultiplier: 2,
      );

      expect(reduced.motor.apparentPowerKva, closeTo(direct.motor.apparentPowerKva, 0.001));
      expect(reduced.motorTransformerPercent, closeTo(direct.motorTransformerPercent, 0.001));
      expect(direct.startingKvaEstimate, closeTo(reduced.startingKvaEstimate * 3, 0.01));
    });

    test('rejeita transformador com potência nominal inválida', () {
      expect(
        () => MotorTransformerCalculator.calculate(
          transformerKva: 0,
          motorRatedPower: 15,
          motorUnit: MotorPowerUnit.cv,
          system: AcSystem.threePhase,
          voltageV: 220,
          powerFactor: 0.85,
          efficiency: 0.90,
        ),
        throwsArgumentError,
      );
    });
  });
}
