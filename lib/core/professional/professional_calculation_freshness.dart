import 'professional_circuit.dart';
import 'professional_load.dart';
import 'professional_sizing.dart';
import 'professional_protection.dart';

class ProfessionalCalculationFreshness {
  const ProfessionalCalculationFreshness._();

  static bool protectionNeedsReview({
    required ProfessionalProtection protection,
    required ProfessionalCircuit circuit,
    required Iterable<ProfessionalLoad> linkedLoads,
    ProfessionalSizing? sizing,
  }) {
    final calculatedAt = protection.updatedAt.toUtc();
    if (circuit.updatedAt.toUtc().isAfter(calculatedAt)) return true;
    if (sizing != null && sizing.updatedAt.toUtc().isAfter(calculatedAt)) return true;
    for (final load in linkedLoads) {
      if (load.updatedAt.toUtc().isAfter(calculatedAt)) return true;
    }
    return false;
  }

  static bool sizingNeedsReview({
    required ProfessionalSizing sizing,
    required ProfessionalCircuit circuit,
    required Iterable<ProfessionalLoad> linkedLoads,
  }) {
    final calculatedAt = sizing.updatedAt.toUtc();
    if (circuit.updatedAt.toUtc().isAfter(calculatedAt)) return true;
    for (final load in linkedLoads) {
      if (load.updatedAt.toUtc().isAfter(calculatedAt)) return true;
    }
    return false;
  }
}
