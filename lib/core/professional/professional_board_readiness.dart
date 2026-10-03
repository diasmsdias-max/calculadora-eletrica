import 'professional_circuit_technical_state.dart';

enum ProfessionalBoardReadinessStatus { ready, pending, reviewRequired }

class ProfessionalBoardReadiness {
  final ProfessionalBoardReadinessStatus status;
  final int totalCircuits;
  final int completeCircuits;
  final int pendingCircuits;
  final int reviewRequiredCircuits;
  final List<String> issues;

  const ProfessionalBoardReadiness({
    required this.status,
    required this.totalCircuits,
    required this.completeCircuits,
    required this.pendingCircuits,
    required this.reviewRequiredCircuits,
    required this.issues,
  });

  bool get isReady => status == ProfessionalBoardReadinessStatus.ready;
}

class ProfessionalBoardReadinessEvaluator {
  const ProfessionalBoardReadinessEvaluator();

  ProfessionalBoardReadiness evaluate(
    Iterable<ProfessionalCircuitTechnicalState> circuits,
  ) {
    final states = circuits.toList(growable: false);
    final complete = states.where((x) => x.status == ProfessionalCircuitTechnicalStatus.complete).length;
    final pending = states.where((x) => x.status == ProfessionalCircuitTechnicalStatus.pending).length;
    final review = states.where((x) => x.status == ProfessionalCircuitTechnicalStatus.reviewRequired).length;
    final issues = <String>[];

    if (states.isEmpty) issues.add('Quadro sem circuitos vinculados.');
    if (pending > 0) issues.add('$pending circuito(s) com pendências.');
    if (review > 0) issues.add('$review circuito(s) precisam de revisão.');

    final status = review > 0
        ? ProfessionalBoardReadinessStatus.reviewRequired
        : (states.isEmpty || pending > 0)
            ? ProfessionalBoardReadinessStatus.pending
            : ProfessionalBoardReadinessStatus.ready;

    return ProfessionalBoardReadiness(
      status: status,
      totalCircuits: states.length,
      completeCircuits: complete,
      pendingCircuits: pending,
      reviewRequiredCircuits: review,
      issues: List.unmodifiable(issues),
    );
  }
}
