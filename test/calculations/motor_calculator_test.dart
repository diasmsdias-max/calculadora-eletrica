import 'package:calculadora_eletrica/core/calculations/motor_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MotorCalculator', () {
    test('motor trifásico 15 CV 220 V FP 0,85 rendimento 90%', () {
      final result = MotorCalculator.calculate(
        ratedPower: 15,
        unit: MotorPowerUnit.cv,
        system: AcSystem.threePhase,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.90,
      );
      expect(result.shaftPowerKw, closeTo(11.03248, 0.0001));
      expect(result.absorbedPowerKw, closeTo(12.25831, 0.0001));
      expect(result.apparentPowerKva, closeTo(14.42154, 0.0001));
      expect(result.nominalCurrentA, closeTo(37.85, 0.05));
    });

    test('calcula fator de serviço sem alterar corrente nominal', () {
      final result = MotorCalculator.calculate(
        ratedPower: 10,
        unit: MotorPowerUnit.kw,
        system: AcSystem.threePhase,
        voltageV: 380,
        powerFactor: 0.85,
        efficiency: 0.90,
        serviceFactor: 1.15,
      );
      expect(result.servicePowerKw, closeTo(11.5, 0.001));
      expect(result.nominalCurrentA, closeTo(19.86, 0.05));
    });

    test('estima partida direta por multiplicador configurável', () {
      final result = MotorCalculator.calculate(
        ratedPower: 15,
        unit: MotorPowerUnit.cv,
        system: AcSystem.threePhase,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.90,
        startingMethod: MotorStartingMethod.direct,
        startingMultiplier: 6,
      );
      expect(result.estimatedStartingCurrentA, closeTo(result.nominalCurrentA * 6, 0.001));
    });

    test('calcula consumo pela potência elétrica absorvida', () {
      final result = MotorCalculator.calculate(
        ratedPower: 9,
        unit: MotorPowerUnit.kw,
        system: AcSystem.threePhase,
        voltageV: 380,
        powerFactor: 0.9,
        efficiency: 0.9,
        hoursPerDay: 8,
        daysPerMonth: 30,
      );
      expect(result.absorbedPowerKw, closeTo(10, 0.001));
      expect(result.dailyEnergyKwh, closeTo(80, 0.001));
      expect(result.monthlyEnergyKwh, closeTo(2400, 0.001));
    });
    test('motor bifásico usa tensão fase-fase sem fator raiz de três', () {
      final result = MotorCalculator.calculate(
        ratedPower: 5,
        unit: MotorPowerUnit.kw,
        system: AcSystem.twoPhase,
        voltageV: 220,
        powerFactor: 0.8,
        efficiency: 0.9,
      );
      expect(result.nominalCurrentA, closeTo(31.5657, 0.01));
    });

    test('calcula potência mecânica a partir da corrente informada', () {
      final result = MotorCalculator.calculateFromCurrent(
        currentA: 40,
        system: AcSystem.threePhase,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.9,
      );
      expect(result.nominalCurrentA, closeTo(40, 0.001));
      expect(result.shaftPowerKw, closeTo(11.662, 0.01));
      expect(result.absorbedPowerKw, closeTo(12.958, 0.01));
    });
  });
}
