import 'electrical_units.dart';
import 'power_calculator.dart';

enum MotorPowerUnit { cv, hp, kw }
enum MotorStartingMethod { direct, starDelta, softStarter, vfd, custom }

extension MotorStartingMethodLabel on MotorStartingMethod {
  String get label => switch (this) {
    MotorStartingMethod.direct => 'Partida direta',
    MotorStartingMethod.starDelta => 'Estrela-triângulo',
    MotorStartingMethod.softStarter => 'Soft-starter',
    MotorStartingMethod.vfd => 'Inversor de frequência',
    MotorStartingMethod.custom => 'Personalizado',
  };
}

class MotorResult {
  final double shaftPowerKw;
  final double servicePowerKw;
  final double absorbedPowerKw;
  final double apparentPowerKva;
  final double nominalCurrentA;
  final double estimatedStartingCurrentA;
  final double dailyEnergyKwh;
  final double monthlyEnergyKwh;

  const MotorResult({
    required this.shaftPowerKw,
    required this.servicePowerKw,
    required this.absorbedPowerKw,
    required this.apparentPowerKva,
    required this.nominalCurrentA,
    required this.estimatedStartingCurrentA,
    required this.dailyEnergyKwh,
    required this.monthlyEnergyKwh,
  });
}

abstract final class MotorCalculator {
  static double suggestedStartingMultiplier(MotorStartingMethod method) => switch (method) {
    MotorStartingMethod.direct => 6.0,
    MotorStartingMethod.starDelta => 2.0,
    MotorStartingMethod.softStarter => 3.0,
    MotorStartingMethod.vfd => 1.5,
    MotorStartingMethod.custom => 1.0,
  };

  static MotorResult calculate({
    required double ratedPower,
    required MotorPowerUnit unit,
    required AcSystem system,
    required double voltageV,
    required double powerFactor,
    required double efficiency,
    double serviceFactor = 1,
    double hoursPerDay = 0,
    int daysPerMonth = 30,
    MotorStartingMethod startingMethod = MotorStartingMethod.direct,
    double? startingMultiplier,
  }) {
    if (!ratedPower.isFinite || ratedPower <= 0) {
      throw ArgumentError('Potência nominal deve ser maior que zero.');
    }
    if (!serviceFactor.isFinite || serviceFactor < 1) {
      throw ArgumentError('Fator de serviço deve ser maior ou igual a 1.');
    }
    if (!hoursPerDay.isFinite || hoursPerDay < 0 || hoursPerDay > 24) {
      throw ArgumentError('Horas/dia inválidas.');
    }
    if (daysPerMonth < 0 || daysPerMonth > 31) {
      throw ArgumentError('Dias/mês inválidos.');
    }

    final multiplier = startingMultiplier ?? suggestedStartingMultiplier(startingMethod);
    if (!multiplier.isFinite || multiplier <= 0) {
      throw ArgumentError('Multiplicador de partida inválido.');
    }

    final shaftKw = switch (unit) {
      MotorPowerUnit.cv => ElectricalUnits.cvToKw(ratedPower),
      MotorPowerUnit.hp => ElectricalUnits.hpToKw(ratedPower),
      MotorPowerUnit.kw => ratedPower,
    };

    final nominalCurrent = PowerCalculator.currentA(
      system: system,
      activePowerKw: shaftKw,
      voltageV: voltageV,
      powerFactor: powerFactor,
      efficiency: efficiency,
    );
    final absorbedKw = shaftKw / efficiency;

    return MotorResult(
      shaftPowerKw: shaftKw,
      servicePowerKw: shaftKw * serviceFactor,
      absorbedPowerKw: absorbedKw,
      apparentPowerKva: absorbedKw / powerFactor,
      nominalCurrentA: nominalCurrent,
      estimatedStartingCurrentA: nominalCurrent * multiplier,
      dailyEnergyKwh: absorbedKw * hoursPerDay,
      monthlyEnergyKwh: absorbedKw * hoursPerDay * daysPerMonth,
    );
  }
}
