import '../calculations/cable_sizing_calculator.dart';
import '../calculations/quick_ampacity_reference.dart';
import 'professional_commercial_catalog.dart';

class ProfessionalConductorRecommendation {
  final double designCurrentA;
  final double requiredReferenceAmpacityA;
  final double? sectionMm2;
  final double? referenceAmpacityA;
  final double? correctedAmpacityA;
  final String method;
  final String message;

  const ProfessionalConductorRecommendation({
    required this.designCurrentA,
    required this.requiredReferenceAmpacityA,
    required this.sectionMm2,
    required this.referenceAmpacityA,
    required this.correctedAmpacityA,
    required this.method,
    required this.message,
  });

  bool get hasRecommendation => sectionMm2 != null && correctedAmpacityA != null;
}

class ProfessionalConductorRecommender {
  const ProfessionalConductorRecommender();

  ProfessionalConductorRecommendation recommendB1({
    required double designCurrentA,
    required QuickAmpacityMaterial material,
    required int loadedConductors,
    double temperatureFactor = 1,
    double groupingFactor = 1,
  }) {
    final sizing = CableSizingCalculator.calculate(
      designCurrentA: designCurrentA,
      temperatureFactor: temperatureFactor,
      groupingFactor: groupingFactor,
    );

    for (final section in ProfessionalCommercialCatalog.conductorSectionsMm2) {
      final reference = QuickAmpacityReference.ampacityA(
        material: material,
        sectionMm2: section,
        loadedConductors: loadedConductors,
      );
      if (reference == null) continue;
      final corrected = sizing.correctedAmpacity(reference);
      if (corrected >= designCurrentA) {
        return ProfessionalConductorRecommendation(
          designCurrentA: designCurrentA,
          requiredReferenceAmpacityA: sizing.requiredAmpacityA,
          sectionMm2: section,
          referenceAmpacityA: reference,
          correctedAmpacityA: corrected,
          method: QuickAmpacityReference.referenceDescription,
          message:
              'Primeira seção comercial da referência B1 que atende à corrente de projeto após os fatores informados.',
        );
      }
    }

    return ProfessionalConductorRecommendation(
      designCurrentA: designCurrentA,
      requiredReferenceAmpacityA: sizing.requiredAmpacityA,
      sectionMm2: null,
      referenceAmpacityA: null,
      correctedAmpacityA: null,
      method: QuickAmpacityReference.referenceDescription,
      message:
          'Nenhuma seção do catálogo profissional atende às condições informadas na referência B1.',
    );
  }
}
