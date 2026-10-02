import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_simultaneity_estimator.dart';

void main() {
  const estimator = ProfessionalSimultaneityEstimator();

  test('estimates FS from simultaneous identical units', () {
    final result = estimator.bySimultaneousQuantity(
      totalQuantity: 4,
      simultaneousQuantity: 3,
      unitPowerW: 10000,
    );
    expect(result.factor, 0.75);
    expect(result.installedPowerW, 40000);
    expect(result.simultaneousPowerW, 30000);
  });

  test('estimates FS from informed simultaneous demand', () {
    final result = estimator.bySimultaneousDemand(
      totalQuantity: 4,
      unitPowerW: 10000,
      simultaneousPowerW: 28000,
    );
    expect(result.factor, closeTo(0.7, 0.000001));
    expect(result.installedPowerW, 40000);
  });

  test('without diversity is an explicit conservative FS 1', () {
    final result = estimator.withoutDiversity(
      totalQuantity: 2,
      unitPowerW: 1500,
    );
    expect(result.factor, 1);
    expect(result.simultaneousPowerW, 3000);
  });

  test('rejects simultaneous quantity above installed quantity', () {
    expect(
      () => estimator.bySimultaneousQuantity(
        totalQuantity: 2,
        simultaneousQuantity: 3,
        unitPowerW: 1000,
      ),
      throwsArgumentError,
    );
  });

  test('rejects simultaneous demand above installed power', () {
    expect(
      () => estimator.bySimultaneousDemand(
        totalQuantity: 2,
        unitPowerW: 1000,
        simultaneousPowerW: 2500,
      ),
      throwsArgumentError,
    );
  });
}
