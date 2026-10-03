import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora_eletrica/core/calculations/quick_ampacity_reference.dart';
import 'package:calculadora_eletrica/core/professional/professional_conductor_recommender.dart';

void main() {
  const recommender = ProfessionalConductorRecommender();

  test('recommends first commercial copper B1 section that meets Ib', () {
    final result = recommender.recommendB1(
      designCurrentA: 20,
      material: QuickAmpacityMaterial.copper,
      loadedConductors: 2,
    );

    expect(result.sectionMm2, 2.5);
    expect(result.referenceAmpacityA, 24);
    expect(result.correctedAmpacityA, 24);
    expect(result.hasRecommendation, isTrue);
  });

  test('applies temperature and grouping factors before choosing section', () {
    final result = recommender.recommendB1(
      designCurrentA: 40,
      material: QuickAmpacityMaterial.copper,
      loadedConductors: 2,
      temperatureFactor: 0.87,
      groupingFactor: 0.8,
    );

    expect(result.requiredReferenceAmpacityA, closeTo(57.47, 0.01));
    expect(result.sectionMm2, 16);
    expect(result.referenceAmpacityA, 76);
    expect(result.correctedAmpacityA, closeTo(52.896, 0.001));
  });

  test('does not invent section when catalog cannot meet the condition', () {
    final result = recommender.recommendB1(
      designCurrentA: 500,
      material: QuickAmpacityMaterial.copper,
      loadedConductors: 3,
    );

    expect(result.sectionMm2, isNull);
    expect(result.hasRecommendation, isFalse);
  });
}
