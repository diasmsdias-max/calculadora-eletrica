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


  test('pending when overcurrent protection has no valid In',(){
    final invalid=ProfessionalProtection(
      id:'pr2',projectId:'p1',circuitId:'c1',revision:1,name:'QF sem In',
      role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:null,
      createdAt:t,updatedAt:t.add(const Duration(minutes:2)));
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[invalid]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.pending);
    expect(r.issues,contains('Proteção de sobrecorrente sem corrente nominal (In) válida.'));
  });


  test('review required when adopted protection violates Ib In Iz criterion',(){
    final invalid=ProfessionalProtection(
      id:'pr3',projectId:'p1',circuitId:'c1',revision:1,name:'QF fora do critério',
      role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:32,
      validationStatus:'nonCompliant',validationCriterion:'Critério aplicado: Ib ≤ In ≤ Iz.',
      createdAt:t,updatedAt:t.add(const Duration(minutes:2)));
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[invalid]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.reviewRequired);
    expect(r.issues,contains('Proteção de sobrecorrente fora do critério Ib ≤ In ≤ Iz.'));
  });

  test('review required when compliant protection has In below Ib',(){
    final invalid=ProfessionalProtection(
      id:'pr4',projectId:'p1',circuitId:'c1',revision:1,name:'QF abaixo de Ib',
      role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:4,
      validationStatus:'compliant',validationCriterion:'Critério aplicado: Ib ≤ In ≤ Iz.',
      createdAt:t,updatedAt:t.add(const Duration(minutes:2)));
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[invalid]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.reviewRequired);
    expect(r.issues,contains('Proteção de sobrecorrente fora do critério Ib ≤ In ≤ Iz.'));
  });

  test('review required when compliant protection has In above Iz',(){
    final invalid=ProfessionalProtection(
      id:'pr5',projectId:'p1',circuitId:'c1',revision:1,name:'QF acima de Iz',
      role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:25,
      validationStatus:'compliant',validationCriterion:'Critério aplicado: Ib ≤ In ≤ Iz.',
      createdAt:t,updatedAt:t.add(const Duration(minutes:2)));
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[invalid]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.reviewRequired);
    expect(r.issues,contains('Proteção de sobrecorrente fora do critério Ib ≤ In ≤ Iz.'));
  });

  test('complete when compliant protection satisfies Ib In Iz criterion',(){
    final valid=ProfessionalProtection(
      id:'pr6',projectId:'p1',circuitId:'c1',revision:1,name:'QF dentro do critério',
      role:ProfessionalProtectionRole.overcurrent,ratedCurrentA:10,
      validationStatus:'compliant',validationCriterion:'Critério aplicado: Ib ≤ In ≤ Iz.',
      createdAt:t,updatedAt:t.add(const Duration(minutes:2)));
    final r=evaluator.evaluate(circuit:circuit(),linkedLoads:[load()],
      sizing:sizing(updated:t.add(const Duration(minutes:1))),
      protections:[valid]);
    expect(r.status,ProfessionalCircuitTechnicalStatus.complete);
    expect(r.issues,isEmpty);
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
