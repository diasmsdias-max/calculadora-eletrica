import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit_technical_state.dart';
import 'package:calculadora_eletrica/core/professional/professional_load.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';
import 'package:calculadora_eletrica/core/professional/professional_sizing.dart';

void main(){
  final t=DateTime.utc(2026,10,3,12);
  ProfessionalCircuit circuit({DateTime? updated})=>ProfessionalCircuit(
    id:'c1',projectId:'p1',revision:1,name:'C1',voltageV:220,phases:1,
    createdAt:t,updatedAt:updated??t);
  ProfessionalLoad load({DateTime? updated})=>ProfessionalLoad(
    id:'l1',projectId:'p1',revision:1,name:'Carga',powerW:1000,voltageV:220,
    createdAt:t,updatedAt:updated??t);
  ProfessionalSizing sizing({DateTime? updated})=>ProfessionalSizing(
    id:'s1',projectId:'p1',circuitId:'c1',revision:1,designCurrentA:5,
    conductorSectionMm2:2.5,conductorAmpacityA:24,createdAt:t,updatedAt:updated??t);
  ProfessionalProtection protection({DateTime? updated})=>ProfessionalProtection(
    id:'pr1',projectId:'p1',circuitId:'c1',revision:1,name:'QF1',
    role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:10,
    createdAt:t,updatedAt:updated??t);

  const evaluator=ProfessionalCircuitTechnicalStateEvaluator();

  test('complete when circuit has load sizing and overcurrent protection current',(){
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[protection(updated:t.add(const Duration(minutes:2)))]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.complete);
    expect(r.issues,isEmpty);
  });

  test('pending when sizing or protection is missing',(){
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:null,protections:const []);
    expect(r.status,ProfessionalCircuitTechnicalStatus.pending);
    expect(r.issues,isNotEmpty);
  });

  test('review required when upstream data is newer',(){
    final r=evaluator.evaluate(
      circuit:circuit(updated:t.add(const Duration(minutes:3))),
      linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[protection(updated:t.add(const Duration(minutes:2)))]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.reviewRequired);
  });
}
