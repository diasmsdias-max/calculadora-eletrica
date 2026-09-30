import 'cable_sizing_calculator.dart';
import 'power_calculator.dart';
import 'voltage_drop_calculator.dart';

class ConductorCheckResult {
  final CableSizingResult ampacity;
  final VoltageDropResult voltageDrop;
  final double referenceAmpacityA;
  final double correctedAmpacityA;
  final bool ampacityMeets;

  const ConductorCheckResult({
    required this.ampacity,
    required this.voltageDrop,
    required this.referenceAmpacityA,
    required this.correctedAmpacityA,
    required this.ampacityMeets,
  });

  bool get meetsBothCriteria => ampacityMeets && voltageDrop.withinLimit;
}

abstract final class ConductorCheckCalculator {
  static ConductorCheckResult calculate({
    required AcSystem system,
    required double voltageV,
    required double designCurrentA,
    required double lengthM,
    required double sectionMm2,
    required ConductorMaterial material,
    required double powerFactor,
    required double maxDropPercent,
    required double temperatureFactor,
    required double groupingFactor,
    required double referenceAmpacityA,
  }) {
    if (!referenceAmpacityA.isFinite || referenceAmpacityA <= 0) {
      throw ArgumentError('Ampacidade de referência inválida.');
    }

    final ampacity = CableSizingCalculator.calculate(
      designCurrentA: designCurrentA,
      temperatureFactor: temperatureFactor,
      groupingFactor: groupingFactor,
    );

    final voltageDrop = VoltageDropCalculator.calculate(
      system: system,
      voltageV: voltageV,
      currentA: designCurrentA,
      lengthM: lengthM,
      sectionMm2: sectionMm2,
      material: material,
      powerFactor: powerFactor,
      maxDropPercent: maxDropPercent,
    );

    return ConductorCheckResult(
      ampacity: ampacity,
      voltageDrop: voltageDrop,
      referenceAmpacityA: referenceAmpacityA,
      correctedAmpacityA: ampacity.correctedAmpacity(referenceAmpacityA),
      ampacityMeets: ampacity.cableMeets(referenceAmpacityA),
    );
  }
}
