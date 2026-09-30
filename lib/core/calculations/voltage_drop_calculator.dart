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

    final rho = _resistivity(material);
    final circuitFactor = system == AcSystem.threePhase ? math.sqrt(3) : 2.0;
    final dropV = circuitFactor * rho * lengthM * currentA * powerFactor / sectionMm2;
    final dropPercent = dropV / voltageV * 100;
    final maxDropV = voltageV * maxDropPercent / 100;
    final minimum = maxDropV == 0
        ? 0.0
        : circuitFactor * rho * lengthM * currentA * powerFactor / maxDropV;

    final commercial = _commercialSections.firstWhere(
      (s) => s >= minimum,
      orElse: () => _commercialSections.last,
    );

    return VoltageDropResult(
      dropV: dropV,
      dropPercent: dropPercent,
      withinLimit: dropPercent <= maxDropPercent,
      minimumSectionMm2: minimum,
      commercialSectionMm2: commercial,
    );
  }
}
