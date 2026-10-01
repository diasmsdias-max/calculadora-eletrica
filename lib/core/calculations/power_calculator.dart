import 'dart:math' as math;

enum AcSystem { singlePhase, twoPhase, threePhase }

abstract final class PowerCalculator {
  static double apparentPowerKva({required double activePowerKw, required double powerFactor}) {
    _positive(activePowerKw, 'Potência ativa');
    _powerFactor(powerFactor);
    return activePowerKw / powerFactor;
  }

  static double currentA({
    required AcSystem system,
    required double activePowerKw,
    required double voltageV,
    required double powerFactor,
    double efficiency = 1,
  }) {
    _positive(activePowerKw, 'Potência');
    _positive(voltageV, 'Tensão');
    _powerFactor(powerFactor);
    _fraction(efficiency, 'Rendimento');
    final inputPowerW = activePowerKw * 1000 / efficiency;
    final factor = system == AcSystem.threePhase ? math.sqrt(3) : 1.0;
    return inputPowerW / (factor * voltageV * powerFactor);
  }

  static double activePowerKwFromCurrent({
    required AcSystem system,
    required double currentA,
    required double voltageV,
    required double powerFactor,
    double efficiency = 1,
  }) {
    _positive(currentA, 'Corrente');
    _positive(voltageV, 'Tensão');
    _powerFactor(powerFactor);
    _fraction(efficiency, 'Rendimento');
    final factor = system == AcSystem.threePhase ? math.sqrt(3) : 1.0;
    return factor * voltageV * currentA * powerFactor * efficiency / 1000;
  }

  static void _positive(double value, String name) {
    if (!value.isFinite || value <= 0) throw ArgumentError('$name deve ser maior que zero.');
  }
  static void _powerFactor(double value) => _fraction(value, 'Fator de potência');
  static void _fraction(double value, String name) {
    if (!value.isFinite || value <= 0 || value > 1) throw ArgumentError('$name deve estar entre 0 e 1.');
  }
}
