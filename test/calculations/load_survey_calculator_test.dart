import 'package:calculadora_eletrica/core/calculations/load_survey_calculator.dart';
import 'package:calculadora_eletrica/core/calculations/power_calculator.dart';
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

    test('calcula corrente trifásica da demanda aparente', () {
      final result = LoadSurveyCalculator.calculate(
        [
          const LoadItem(
            description: 'Carga',
            unitPowerKw: 8.8,
            quantity: 1,
            powerFactor: 0.8,
            simultaneity: 1,
            hoursPerDay: 8,
          ),
        ],
        system: AcSystem.threePhase,
        voltageV: 220,
      );
      expect(result.apparentKva, closeTo(11, 0.001));
      expect(result.demandCurrentA, closeTo(28.87, 0.02));
    });

    test('lista vazia retorna zero', () {
      final result = LoadSurveyCalculator.calculate([]);
      expect(result.installedKw, 0);
      expect(result.demandKw, 0);
      expect(result.apparentKva, 0);
      expect(result.dailyKwh, 0);
      expect(result.monthlyKwh, 0);
    });
    test('rejeita sistema sem tensão correspondente', () {
      expect(
        () => LoadSurveyCalculator.calculate([], system: AcSystem.threePhase),
        throwsArgumentError,
      );
    });

    test('rejeita tensão sem sistema correspondente', () {
      expect(
        () => LoadSurveyCalculator.calculate([], voltageV: 220),
        throwsArgumentError,
      );
    });

    test('rejeita tensão inválida mesmo com lista vazia', () {
      expect(
        () => LoadSurveyCalculator.calculate(
          [],
          system: AcSystem.threePhase,
          voltageV: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejeita quantidade de dias fora do intervalo', () {
      expect(
        () => LoadSurveyCalculator.calculate([], daysPerMonth: 32),
        throwsArgumentError,
      );
    });
  });
}
