import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora_eletrica/core/professional/overcurrent_protection_recommender.dart';

void main() {
  const recommender = OvercurrentProtectionRecommender();

  test('recommends first commercial In satisfying Ib <= In <= Iz', () {
    final result = recommender.recommend(
      designCurrentA: 18.4,
      conductorAmpacityA: 24,
    );

    expect(result.status, OvercurrentRecommendationStatus.recommended);
    expect(result.recommendedCurrentA, 20);
    expect(result.hasRecommendation, isTrue);
  });

  test('does not recommend when commercial rating would exceed Iz', () {
    final result = recommender.recommend(
      designCurrentA: 18.4,
      conductorAmpacityA: 19,
    );

    expect(
      result.status,
      OvercurrentRecommendationStatus.noCompatibleCommercialRating,
    );
    expect(result.recommendedCurrentA, isNull);
    expect(result.hasRecommendation, isFalse);
  });

  test('does not recommend without Ib or Iz', () {
    expect(
      recommender.recommend(designCurrentA: null, conductorAmpacityA: 25).status,
      OvercurrentRecommendationStatus.insufficientData,
    );
    expect(
      recommender.recommend(designCurrentA: 10, conductorAmpacityA: null).status,
      OvercurrentRecommendationStatus.insufficientData,
    );
  });

  test('does not invent rating above commercial catalog', () {
    final result = recommender.recommend(
      designCurrentA: 130,
      conductorAmpacityA: 200,
    );

    expect(
      result.status,
      OvercurrentRecommendationStatus.noCompatibleCommercialRating,
    );
    expect(result.recommendedCurrentA, isNull);
  });
}
