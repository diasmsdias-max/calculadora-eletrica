enum TechnicalValidationStatus {
  compliant,
  attention,
  nonCompliant,
  insufficientData,
}

class TechnicalValidationResult {
  final TechnicalValidationStatus status;
  final String code;
  final String title;
  final String message;
  final String? criterion;
  final double? calculatedValue;
  final double? recommendedValue;
  final double? adoptedValue;
  final String? unit;

  const TechnicalValidationResult({
    required this.status,
    required this.code,
    required this.title,
    required this.message,
    this.criterion,
    this.calculatedValue,
    this.recommendedValue,
    this.adoptedValue,
    this.unit,
  });

  bool get requiresAttention =>
      status == TechnicalValidationStatus.attention ||
      status == TechnicalValidationStatus.nonCompliant;

  bool get canBeValidated =>
      status != TechnicalValidationStatus.insufficientData;
}
