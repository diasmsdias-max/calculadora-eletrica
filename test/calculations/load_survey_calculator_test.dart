import 'package:calculadora_eletrica/core/calculations/load_survey_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadSurveyCalculator', () {
    test('soma cargas com fatores individuais', () {
      final result = LoadSurveyCalculator.calculate([
        const LoadItem(
          description: 'Iluminação',
          unitPowerKw: 0.1,
          quantity: 10,
          powerFactor: 1,
          simultaneity: 0.8,
          hoursPerDay: 5,
        ),
        const LoadItem(
          description: 'Motor',
          unitPowerKw: 5,
          quantity: 1,
          powerFactor: 0.8,
          simultaneity: 1,
          hoursPerDay: 4,
        ),
      ]);

      expect(result.installedKw, closeTo(6, 0.001));
      expect(result.demandKw, closeTo(5.8, 0.001));
      expect(result.apparentKva, closeTo(7.05, 0.001));
      expect(result.dailyKwh, closeTo(25, 0.001));
      expect(result.monthlyKwh, closeTo(750, 0.001));
    });

    test('lista vazia retorna zero', () {
      final result = LoadSurveyCalculator.calculate([]);
      expect(result.installedKw, 0);
      expect(result.demandKw, 0);
      expect(result.apparentKva, 0);
      expect(result.dailyKwh, 0);
      expect(result.monthlyKwh, 0);
    });
  });
}
