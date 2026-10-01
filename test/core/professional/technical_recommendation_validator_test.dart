import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/technical_recommendation_validator.dart';
import 'package:calculadora_eletrica/core/professional/technical_validation.dart';

void main() {
  group('TechnicalRecommendationValidator', () {
    test('reports insufficient data without inventing a recommendation', () {
      final result = TechnicalRecommendationValidator.validateMinimum(
        code: 'protection.current',
        subject: 'proteção do circuito',
        recommendedValue: null,
        adoptedValue: 16,
        unit: 'A',
      );

      expect(result.status, TechnicalValidationStatus.insufficientData);
      expect(result.canBeValidated, isFalse);
    });

    test('flags adopted value below the applied minimum', () {
      final result = TechnicalRecommendationValidator.validateMinimum(
        code: 'protection.current',
        subject: 'proteção do circuito',
        recommendedValue: 32,
        adoptedValue: 16,
        unit: 'A',
        criterion: 'Critério técnico aplicado ao circuito',
      );

      expect(result.status, TechnicalValidationStatus.nonCompliant);
      expect(result.requiresAttention, isTrue);
      expect(result.recommendedValue, 32);
      expect(result.adoptedValue, 16);
    });

    test('accepts adopted value that meets the applied minimum', () {
      final result = TechnicalRecommendationValidator.validateMinimum(
        code: 'protection.current',
        subject: 'proteção do circuito',
        recommendedValue: 32,
        adoptedValue: 32,
        unit: 'A',
      );

      expect(result.status, TechnicalValidationStatus.compliant);
      expect(result.requiresAttention, isFalse);
    });

    test('marks a different exact recommendation as attention', () {
      final result =
          TechnicalRecommendationValidator.validateExactRecommendation(
        code: 'example.exact',
        subject: 'valor técnico',
        recommendedValue: 10,
        adoptedValue: 12,
        unit: 'A',
      );

      expect(result.status, TechnicalValidationStatus.attention);
      expect(result.requiresAttention, isTrue);
    });
  });
}
