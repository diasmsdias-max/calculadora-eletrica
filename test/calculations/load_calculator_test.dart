import 'package:calculadora_eletrica/core/calculations/load_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula carga, simultaneidade, kVA e consumo', () {
    final result = LoadCalculator.calculate(
      unitPowerKw: 1.5,
      quantity: 3,
      powerFactor: 0.9,
      simultaneity: 0.7,
      hoursPerDay: 8,
      daysPerMonth: 30,
    );

    expect(result.installedKw, closeTo(4.5, 1e-9));
    expect(result.demandKw, closeTo(3.15, 1e-9));
    expect(result.apparentKva, closeTo(3.5, 1e-9));
    expect(result.dailyKwh, closeTo(36, 1e-9));
    expect(result.monthlyKwh, closeTo(1080, 1e-9));
  });
}
