import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit_aggregation.dart';
import 'package:calculadora_eletrica/core/professional/professional_circuit_technical_inputs.dart';
import 'package:calculadora_eletrica/core/professional/professional_sizing.dart';
import 'package:calculadora_eletrica/core/professional/professional_protection.dart';

void main() {
  final now=DateTime.utc(2026,1,1);

  ProfessionalSizing sizing({double? section=2.5,double? ampacity=24,double? protection=20}) =>
    ProfessionalSizing(
      id:'s1',projectId:'p1',circuitId:'c1',revision:1,
      designCurrentA:18,conductorSectionMm2:section,conductorAmpacityA:ampacity,
      protectionCurrentA:protection,method:'Método informado',
      criteria:'Critério informado',createdAt:now,updatedAt:now,
    );

  ProfessionalProtection protection({double? current=25,ProfessionalProtectionRole? role=ProfessionalProtectionRole.overcurrent}) => ProfessionalProtection(
    id:'pr1',projectId:'p1',circuitId:'c1',revision:1,name:'QF1',
    role:role,ratedCurrentA:current,createdAt:now,updatedAt:now,
  );

  const aggregation=ProfessionalCircuitAggregation(
    totalPowerW:3960,linkedLoadCount:1,totalQuantity:1,
    designCurrentA:18,currentStatus:CircuitCalculationStatus.calculated,
    currentMessage:'Calculado',
  );

  test('portable sizing preserves conductor ampacity',(){
    final original=sizing();
    final decoded=ProfessionalSizing.fromPortableJson(original.toPortableJson());
    expect(decoded.conductorAmpacityA,24);
    expect(decoded.conductorSectionMm2,2.5);
    expect(decoded.protectionCurrentA,20);
  });

  test('old portable sizing without ampacity remains readable',(){
    final json=sizing().toPortableJson()..remove('conductorAmpacityA');
    final decoded=ProfessionalSizing.fromPortableJson(json);
    expect(decoded.conductorAmpacityA,isNull);
    expect(decoded.conductorSectionMm2,2.5);
  });

  test('technical inputs are complete when Ib section and Iz exist',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    final result=builder.build(aggregation:aggregation,sizing:sizing());
    expect(result.designCurrentA,18);
    expect(result.conductorAmpacityA,24);
    expect(result.canRecommendOvercurrentProtection,isTrue);
    expect(result.missingForProtectionRecommendation,isEmpty);
  });

  test('technical inputs use protection rated current as authoritative In',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    final result=builder.build(
      aggregation:aggregation,
      sizing:sizing(protection:20),
      protection:protection(current:25),
    );
    expect(result.adoptedProtectionCurrentA,25);
  });

  test('technical inputs ignore residual-current device as source of In',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    final result=builder.build(
      aggregation:aggregation,
      sizing:sizing(protection:20),
      protection:protection(
        current:30,
        role:ProfessionalProtectionRole.residualCurrent,
      ),
    );
    expect(result.adoptedProtectionCurrentA,20);
  });

  test('unclassified legacy protection does not override legacy In',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    final result=builder.build(
      aggregation:aggregation,
      sizing:sizing(protection:20),
      protection:protection(current:30,role:null),
    );
    expect(result.adoptedProtectionCurrentA,20);
  });

  test('technical inputs keep legacy sizing protection as fallback',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    final result=builder.build(aggregation:aggregation,sizing:sizing(protection:20));
    expect(result.adoptedProtectionCurrentA,20);
  });

  test('technical inputs explain missing conductor ampacity',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    final result=builder.build(aggregation:aggregation,sizing:sizing(ampacity:null));
    expect(result.canRecommendOvercurrentProtection,isFalse);
    expect(result.missingForProtectionRecommendation,
      contains('capacidade de condução do condutor (Iz)'));
  });

  test('technical inputs explain missing design current and section',(){
    const builder=ProfessionalCircuitTechnicalInputsBuilder();
    const incompleteAggregation=ProfessionalCircuitAggregation(
      totalPowerW:0,linkedLoadCount:0,totalQuantity:0,designCurrentA:null,
      currentStatus:CircuitCalculationStatus.insufficientData,
      currentMessage:'Dados insuficientes',
    );
    final result=builder.build(
      aggregation:incompleteAggregation,
      sizing:sizing(section:null,ampacity:null),
    );
    expect(result.missingForProtectionRecommendation,
      containsAll(['corrente de projeto (Ib)','seção do condutor',
        'capacidade de condução do condutor (Iz)']));
  });
}
