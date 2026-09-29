import 'dart:math' as math;
import 'power_calculator.dart';

class TransformerResult {
  final double ratedKva;
  final double availableCurrentA;
  final double availableActivePowerKw;
  final double loadKva;
  final double loadPercent;
  final double remainingKva;
  final bool meetsLoad;

  const TransformerResult({
    required this.ratedKva,
    required this.availableCurrentA,
    required this.availableActivePowerKw,
    required this.loadKva,
    required this.loadPercent,
    required this.remainingKva,
    required this.meetsLoad,
  });
}

abstract final class TransformerCalculator {
  static TransformerResult calculate({
    required double ratedKva,
    required AcSystem system,
    required double voltageV,
    required double loadPowerFactor,
    double loadKw = 0,
    double? loadKva,
  }) {
    if (!ratedKva.isFinite || ratedKva <= 0) {
      throw ArgumentError('Potência do transformador deve ser maior que zero.');
    }
    if (!voltageV.isFinite || voltageV <= 0) {
      throw ArgumentError('Tensão deve ser maior que zero.');
    }
    if (!loadPowerFactor.isFinite || loadPowerFactor <= 0 || loadPowerFactor > 1) {
      throw ArgumentError('Fator de potência deve estar entre 0 e 1.');
    }
    if (!loadKw.isFinite || loadKw < 0 || (loadKva != null && (!loadKva.isFinite || loadKva < 0))) {
      throw ArgumentError('Carga inválida.');
    }

    final effectiveLoadKva = loadKva ?? (loadKw / loadPowerFactor);
    final factor = system == AcSystem.threePhase ? math.sqrt(3) : 1.0;
    final current = ratedKva * 1000 / (factor * voltageV);
    final remaining = ratedKva - effectiveLoadKva;

    return TransformerResult(
      ratedKva: ratedKva,
      availableCurrentA: current,
      availableActivePowerKw: ratedKva * loadPowerFactor,
      loadKva: effectiveLoadKva,
      loadPercent: effectiveLoadKva / ratedKva * 100,
      remainingKva: remaining > 0 ? remaining : 0,
      meetsLoad: effectiveLoadKva <= ratedKva,
    );
  }
}
