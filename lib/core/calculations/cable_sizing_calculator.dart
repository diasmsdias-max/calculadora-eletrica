class CableSizingResult {
  final double designCurrentA;
  final double temperatureFactor;
  final double groupingFactor;
  final double combinedCorrectionFactor;
  final double requiredAmpacityA;

  const CableSizingResult({
    required this.designCurrentA,
    required this.temperatureFactor,
    required this.groupingFactor,
    required this.combinedCorrectionFactor,
    required this.requiredAmpacityA,
  });

  bool cableMeets(double referenceAmpacityA) =>
      referenceAmpacityA * combinedCorrectionFactor >= designCurrentA;

  double correctedAmpacity(double referenceAmpacityA) =>
      referenceAmpacityA * combinedCorrectionFactor;
}

abstract final class CableSizingCalculator {
  static CableSizingResult calculate({
    required double designCurrentA,
    required double temperatureFactor,
    required double groupingFactor,
  }) {
    if (!designCurrentA.isFinite || designCurrentA < 0) {
      throw ArgumentError('Corrente de projeto inválida.');
    }
    if (!temperatureFactor.isFinite ||
        temperatureFactor <= 0 ||
        temperatureFactor > 1) {
      throw ArgumentError('Fator de temperatura inválido.');
    }
    if (!groupingFactor.isFinite ||
        groupingFactor <= 0 ||
        groupingFactor > 1) {
      throw ArgumentError('Fator de agrupamento inválido.');
    }

    final combined = temperatureFactor * groupingFactor;
    return CableSizingResult(
      designCurrentA: designCurrentA,
      temperatureFactor: temperatureFactor,
      groupingFactor: groupingFactor,
      combinedCorrectionFactor: combined,
      requiredAmpacityA: designCurrentA / combined,
    );
  }
}
