import 'package:calculadora_eletrica/core/formatters/technical_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats technical decimals in pt-BR', () {
    expect(TechnicalFormat.number(37.85), '37,85');
    expect(TechnicalFormat.number(2.68), '2,68');
    expect(TechnicalFormat.number(15, decimals: 1), '15,0');
  });

  test('formats thousands in pt-BR', () {
    expect(TechnicalFormat.number(2941.99), '2.941,99');
    expect(TechnicalFormat.number(1000000), '1.000.000,00');
  });

  test('formats negative values and units', () {
    expect(TechnicalFormat.number(-1234.5), '-1.234,50');
    expect(TechnicalFormat.unit(14.42, 'kVA'), '14,42 kVA');
  });
}
