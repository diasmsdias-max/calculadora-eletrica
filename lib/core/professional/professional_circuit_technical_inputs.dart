import 'professional_circuit_aggregation.dart';
import 'professional_sizing.dart';
import 'professional_protection.dart';

class ProfessionalCircuitTechnicalInputs {
  final double? designCurrentA;
  final double? conductorSectionMm2;
  final double? conductorAmpacityA;
  final double? adoptedProtectionCurrentA;
  final String sizingMethod;
  final String sizingCriteria;
  final List<String> missingForProtectionRecommendation;

  const ProfessionalCircuitTechnicalInputs({
    required this.designCurrentA,
    required this.conductorSectionMm2,
    required this.conductorAmpacityA,
    required this.adoptedProtectionCurrentA,
    required this.sizingMethod,
    required this.sizingCriteria,
    required this.missingForProtectionRecommendation,
  });

  bool get canRecommendOvercurrentProtection =>
      missingForProtectionRecommendation.isEmpty;
}

class ProfessionalCircuitTechnicalInputsBuilder {
  const ProfessionalCircuitTechnicalInputsBuilder();

  ProfessionalCircuitTechnicalInputs build({
    required ProfessionalCircuitAggregation aggregation,
    ProfessionalSizing? sizing,
    ProfessionalProtection? protection,
  }) {
    final conductorAmpacityA=sizing?.conductorAmpacityA;
    final designCurrent=aggregation.designCurrentA;
    final section=sizing?.conductorSectionMm2;
    final missing=<String>[];

    if(designCurrent==null) missing.add('corrente de projeto (Ib)');
    if(section==null) missing.add('seção do condutor');
    if(conductorAmpacityA==null) {
      missing.add('capacidade de condução do condutor (Iz)');
    }

    return ProfessionalCircuitTechnicalInputs(
      designCurrentA:designCurrent,
      conductorSectionMm2:section,
      conductorAmpacityA:conductorAmpacityA,
      adoptedProtectionCurrentA:protection?.role==ProfessionalProtectionRole.overcurrent
          ? protection?.ratedCurrentA
          : sizing?.protectionCurrentA,
      sizingMethod:sizing?.method ?? '',
      sizingCriteria:sizing?.criteria ?? '',
      missingForProtectionRecommendation:List.unmodifiable(missing),
    );
  }
}
