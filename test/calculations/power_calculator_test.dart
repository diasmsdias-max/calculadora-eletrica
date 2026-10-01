import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PowerCalculator', () {
    test('corrente trifásica de 10 kW em 220 V, FP 0,8', () {
      final current = PowerCalculator.currentA(
        system: AcSystem.threePhase,
        activePowerKw: 10,
        voltageV: 220,
        powerFactor: 0.8,
      );
      expect(current, closeTo(32.80, 0.02));
    });

    test('corrente monofásica de 2,2 kW em 220 V, FP 1', () {
      final current = PowerCalculator.currentA(
        system: AcSystem.singlePhase,
        activePowerKw: 2.2,
        voltageV: 220,
        powerFactor: 1,
      );
      expect(current, closeTo(10, 0.001));
    });

    test('considera rendimento quando potência informada é de saída', () {
      final current = PowerCalculator.currentA(
        system: AcSystem.threePhase,
        activePowerKw: 11.03248125,
        voltageV: 220,
        powerFactor: 0.85,
        efficiency: 0.9,
      );
      expect(current, closeTo(37.84, 0.05));
    });

    test('rejeita fator de potência maior que 1', () {
      expect(
        () => PowerCalculator.apparentPowerKva(
          activePowerKw: 10,
          powerFactor: 1.1,
        ),
        throwsArgumentError,
      );
    });
  });
}
