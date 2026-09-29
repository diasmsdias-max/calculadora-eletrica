import 'electrical_units.dart';
import 'power_calculator.dart';

enum MotorPowerUnit { cv, hp, kw }

class MotorResult {
  final double shaftPowerKw;
  final double absorbedPowerKw;
  final double apparentPowerKva;
  final double nominalCurrentA;

  const MotorResult({
    required this.shaftPowerKw,
    required this.absorbedPowerKw,
    required this.apparentPowerKva,
    required this.nominalCurrentA,
  });
}

abstract final class MotorCalculator {
  static MotorResult calculate({
    required double ratedPower,
    required MotorPowerUnit unit,
    required AcSystem system,
    required double voltageV,
    required double powerFactor,
    required double efficiency,
  }) {
    if (!ratedPower.isFinite || ratedPower <= 0) {
      throw ArgumentError('Potência nominal deve ser maior que zero.');
    }

    final shaftKw = switch (unit) {
      MotorPowerUnit.cv => ElectricalUnits.cvToKw(ratedPower),
      MotorPowerUnit.hp => ElectricalUnits.hpToKw(ratedPower),
      MotorPowerUnit.kw => ratedPower,
    };

    final current = PowerCalculator.currentA(
      system: system,
      activePowerKw: shaftKw,
      voltageV: voltageV,
      powerFactor: powerFactor,
      efficiency: efficiency,
    );
    final absorbedKw = shaftKw / efficiency;

    return MotorResult(
      shaftPowerKw: shaftKw,
      absorbedPowerKw: absorbedKw,
      apparentPowerKva: absorbedKw / powerFactor,
      nominalCurrentA: current,
    );
  }
}
