import 'professional_commercial_catalog.dart';

enum OvercurrentRecommendationStatus {
  recommended,
  insufficientData,
  noCompatibleCommercialRating,
}

class OvercurrentProtectionRecommendation {
  final OvercurrentRecommendationStatus status;
  final double? recommendedCurrentA;
  final String message;
  final String criterion;

  const OvercurrentProtectionRecommendation({
    required this.status,
    required this.recommendedCurrentA,
    required this.message,
    this.criterion = 'Critério aplicado: Ib ≤ In ≤ Iz.',
  });

  bool get hasRecommendation =>
      status == OvercurrentRecommendationStatus.recommended &&
      recommendedCurrentA != null;
}

class OvercurrentProtectionRecommender {
  const OvercurrentProtectionRecommender();

  OvercurrentProtectionRecommendation recommend({
    required double? designCurrentA,
    required double? conductorAmpacityA,
  }) {
    if (designCurrentA == null ||
        designCurrentA <= 0 ||
        conductorAmpacityA == null ||
        conductorAmpacityA <= 0) {
      return const OvercurrentProtectionRecommendation(
        status: OvercurrentRecommendationStatus.insufficientData,
        recommendedCurrentA: null,
        message:
            'Informe a corrente de projeto (Ib) e a capacidade de condução do condutor (Iz) para o VIS recomendar a proteção.',
      );
    }

    final candidate =
        ProfessionalCommercialCatalog.firstBreakerAtOrAbove(designCurrentA);
    if (candidate == null || candidate > conductorAmpacityA) {
      return const OvercurrentProtectionRecommendation(
        status: OvercurrentRecommendationStatus.noCompatibleCommercialRating,
        recommendedCurrentA: null,
        message:
            'Não há corrente nominal comercial do catálogo que satisfaça Ib ≤ In ≤ Iz. Revise o dimensionamento do circuito.',
      );
    }

    return OvercurrentProtectionRecommendation(
      status: OvercurrentRecommendationStatus.recommended,
      recommendedCurrentA: candidate,
      message:
          'O VIS encontrou a primeira corrente nominal comercial que atende a Ib ≤ In ≤ Iz.',
    );
  }
}
