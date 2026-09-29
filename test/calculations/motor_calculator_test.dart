import 'package:calculadora_eletrica/core/calculations/motor_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
