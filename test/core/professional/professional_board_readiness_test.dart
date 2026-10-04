import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_board_readiness.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit_technical_state.dart';

void main(){
  const evaluator=ProfessionalBoardReadinessEvaluator();
  const complete=ProfessionalCircuitTechnicalState(ProfessionalCircuitTechnicalStatus.complete,[]);
  const pending=ProfessionalCircuitTechnicalState(ProfessionalCircuitTechnicalStatus.pending,['Pendente']);
  const review=ProfessionalCircuitTechnicalState(ProfessionalCircuitTechnicalStatus.reviewRequired,['Revisar']);

  test('ready only when all linked circuits are complete',(){
    final r=evaluator.evaluate([complete,complete]);
    expect(r.status,ProfessionalBoardReadinessStatus.ready);
    expect(r.totalCircuits,2);expect(r.completeCircuits,2);expect(r.issues,isEmpty);
  });

  test('empty board is pending',(){
    final r=evaluator.evaluate(const []);
    expect(r.status,ProfessionalBoardReadinessStatus.pending);
    expect(r.issues,contains('Quadro sem circuitos vinculados.'));
  });

  test('pending circuits keep board pending',(){
    final r=evaluator.evaluate([complete,pending]);
    expect(r.status,ProfessionalBoardReadinessStatus.pending);
    expect(r.pendingCircuits,1);
  });

  test('review required has priority over pending',(){
    final r=evaluator.evaluate([complete,pending,review]);
    expect(r.status,ProfessionalBoardReadinessStatus.reviewRequired);
    expect(r.reviewRequiredCircuits,1);
  });
}
