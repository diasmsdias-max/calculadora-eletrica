import 'package:calculadora_eletrica/core/calculations/electrical_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte CV para kW', () {
    expect(ElectricalUnits.cvToKw(1), closeTo(0.73549875, 1e-8));
    expect(ElectricalUnits.cvToKw(15), closeTo(11.03248125, 1e-8));
  });

  test('converte HP para kW', () {
    expect(ElectricalUnits.hpToKw(1), closeTo(0.745699872, 1e-8));
  });
}
