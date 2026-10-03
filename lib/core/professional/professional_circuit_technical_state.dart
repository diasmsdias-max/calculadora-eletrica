import 'professional_calculation_freshness.dart';
import 'professional_circuit.dart';
import 'professional_load.dart';
import 'professional_protection.dart';
import 'professional_sizing.dart';

enum ProfessionalCircuitTechnicalStatus { complete, pending, reviewRequired }

class ProfessionalCircuitTechnicalState {
  final ProfessionalCircuitTechnicalStatus status;
  final List<String> issues;
  const ProfessionalCircuitTechnicalState(this.status, this.issues);

  bool get isComplete => status == ProfessionalCircuitTechnicalStatus.complete;
}

class ProfessionalCircuitTechnicalStateEvaluator {
  const ProfessionalCircuitTechnicalStateEvaluator();

  ProfessionalCircuitTechnicalState evaluate({
    required ProfessionalCircuit circuit,
    required Iterable<ProfessionalLoad> linkedLoads,
    ProfessionalSizing? sizing,
    required Iterable<ProfessionalProtection> protections,
  }) {
    final loads = linkedLoads.toList(growable: false);
    final devices = protections.toList(growable: false);
    final issues = <String>[];

    if (loads.isEmpty) issues.add('Circuito sem cargas vinculadas.');
    if (circuit.voltageV == null || circuit.phases == null) {
      issues.add('Dados elétricos do circuito incompletos.');
    }
    if (sizing == null) {
      issues.add('Dimensionamento ainda não realizado.');
    }
    final overcurrent = devices.where(
      (p) => p.role == ProfessionalProtectionRole.overcurrent,
    ).toList(growable: false);
    if (overcurrent.isEmpty) {
      issues.add('Proteção de sobrecorrente ainda não definida.');
    }

    if (sizing != null &&
        ProfessionalCalculationFreshness.sizingNeedsReview(
          sizing: sizing,
          circuit: circuit,
          linkedLoads: loads,
        )) {
      issues.add('Dimensionamento precisa ser revisado.');
    }

    for (final protection in devices) {
      if (ProfessionalCalculationFreshness.protectionNeedsReview(
        protection: protection,
        circuit: circuit,
        linkedLoads: loads,
        sizing: sizing,
      )) {
        issues.add('Proteção ${protection.name} precisa ser revisada.');
      }
    }

    final review = issues.any((x) => x.contains('precisa ser revisad'));
    return ProfessionalCircuitTechnicalState(
      review
          ? ProfessionalCircuitTechnicalStatus.reviewRequired
          : issues.isEmpty
              ? ProfessionalCircuitTechnicalStatus.complete
              : ProfessionalCircuitTechnicalStatus.pending,
      List.unmodifiable(issues),
    );
  }
}
