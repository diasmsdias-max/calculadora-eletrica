import 'dart:math' as math;
import 'power_calculator.dart';

enum ConductorMaterial { copper, aluminum }

class VoltageDropResult {
  final double dropV;
  final double dropPercent;
  final bool withinLimit;
  final double minimumSectionMm2;
  final double commercialSectionMm2;

  const VoltageDropResult({
    required this.dropV,
    required this.dropPercent,
    required this.withinLimit,
    required this.minimumSectionMm2,
    required this.commercialSectionMm2,
  });
}

abstract final class VoltageDropCalculator {
  static const _commercialSections = <double>[
    1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300,
  ];

  static double _resistivity(ConductorMaterial material) =>
      material == ConductorMaterial.copper ? 0.0175 : 0.0282;

  static VoltageDropResult calculate({
    required AcSystem system,
    required double voltageV,
    required double currentA,
    required double lengthM,
    required double sectionMm2,
    required ConductorMaterial material,
    required double powerFactor,
    required double maxDropPercent,
    double reactanceOhmPerKm = 0,
  }) {
    if (!voltageV.isFinite || voltageV <= 0 ||
        !currentA.isFinite || currentA < 0 ||
        !lengthM.isFinite || lengthM < 0 ||
        !sectionMm2.isFinite || sectionMm2 <= 0) {
      throw ArgumentError('Valores elétricos inválidos.');
    }
    if (!powerFactor.isFinite || powerFactor <= 0 || powerFactor > 1) {
      throw ArgumentError('Fator de potência inválido.');
    }
    if (!maxDropPercent.isFinite || maxDropPercent <= 0) {
      throw ArgumentError('Limite de queda inválido.');
    }
    if (!reactanceOhmPerKm.isFinite || reactanceOhmPerKm < 0) {
      throw ArgumentError('Reatância inválida.');
    }

    final rho = _resistivity(material);
    final circuitFactor = system == AcSystem.threePhase ? math.sqrt(3) : 2.0;
    final resistanceOhm = rho * lengthM / sectionMm2;
    final reactanceOhm = reactanceOhmPerKm * lengthM / 1000;
    final sinPhi = math.sqrt(math.max(0, 1 - powerFactor * powerFactor));
    final dropV = circuitFactor * currentA *
        (resistanceOhm * powerFactor + reactanceOhm * sinPhi);
    final dropPercent = dropV / voltageV * 100;
    final maxDropV = voltageV * maxDropPercent / 100;

    // Minimum section is isolated from the resistive term while preserving
    // the optional reactive voltage-drop component.
    final reactiveDropV = circuitFactor * currentA * reactanceOhm * sinPhi;
    final resistiveBudgetV = maxDropV - reactiveDropV;
    final minimum = resistiveBudgetV <= 0
        ? double.infinity
        : circuitFactor * rho * lengthM * currentA * powerFactor /
            resistiveBudgetV;

    final commercial = minimum.isFinite
        ? _commercialSections.firstWhere(
            (s) => s >= minimum,
            orElse: () => _commercialSections.last,
          )
        : _commercialSections.last;

    return VoltageDropResult(
      dropV: dropV,
      dropPercent: dropPercent,
      withinLimit: dropPercent <= maxDropPercent,
      minimumSectionMm2: minimum,
      commercialSectionMm2: commercial,
    );
  }
}
