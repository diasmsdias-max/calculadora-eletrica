import 'professional_circuit.dart';
import 'professional_load.dart';
import 'professional_sizing.dart';

class ProfessionalCalculationFreshness {
  const ProfessionalCalculationFreshness._();

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
