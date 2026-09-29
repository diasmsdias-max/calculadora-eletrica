import 'dart:math' as math;
import 'load_calculator.dart';
import 'power_calculator.dart';

class LoadItem {
  final String description;
  final double unitPowerKw;
  final int quantity;
  final double powerFactor;
  final double simultaneity;
  final double hoursPerDay;

  const LoadItem({
    required this.description,
    required this.unitPowerKw,
    required this.quantity,
    required this.powerFactor,
    required this.simultaneity,
    required this.hoursPerDay,
  });
}

class LoadSurveyResult {
  final double installedKw;
  final double demandKw;
  final double apparentKva;
  final double dailyKwh;
  final double monthlyKwh;
  final double? demandCurrentA;

  const LoadSurveyResult({
    required this.installedKw,
    required this.demandKw,
    required this.apparentKva,
    required this.dailyKwh,
    required this.monthlyKwh,
    this.demandCurrentA,
  });
}

abstract final class LoadSurveyCalculator {
  static LoadSurveyResult calculate(
    List<LoadItem> items, {
    int daysPerMonth = 30,
    AcSystem? system,
    double? voltageV,
  }) {
    if (items.isEmpty) {
      return const LoadSurveyResult(
        installedKw: 0,
        demandKw: 0,
        apparentKva: 0,
        dailyKwh: 0,
        monthlyKwh: 0,
        demandCurrentA: 0,
      );
    }

    var installed = 0.0;
    var demand = 0.0;
    var apparent = 0.0;
    var daily = 0.0;
    var monthly = 0.0;

    for (final item in items) {
      final result = LoadCalculator.calculate(
        unitPowerKw: item.unitPowerKw,
        quantity: item.quantity,
        powerFactor: item.powerFactor,
        simultaneity: item.simultaneity,
        hoursPerDay: item.hoursPerDay,
        daysPerMonth: daysPerMonth,
      );
      installed += result.installedKw;
      demand += result.demandKw;
      apparent += result.apparentKva;
      daily += result.dailyKwh;
      monthly += result.monthlyKwh;
    }

    double? current;
    if (system != null && voltageV != null) {
      if (!voltageV.isFinite || voltageV <= 0) {
        throw ArgumentError('Tensão inválida.');
      }
      final factor = system == AcSystem.threePhase ? math.sqrt(3) : 1.0;
      current = apparent * 1000 / (factor * voltageV);
    }

    return LoadSurveyResult(
      installedKw: installed,
      demandKw: demand,
      apparentKva: apparent,
      dailyKwh: daily,
      monthlyKwh: monthly,
      demandCurrentA: current,
    );
  }
}
