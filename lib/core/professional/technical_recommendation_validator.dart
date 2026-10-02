import 'technical_validation.dart';

class TechnicalRecommendationValidator {
  const TechnicalRecommendationValidator._();

  static TechnicalValidationResult validateMinimum({
    required String code,
    required String subject,
    required double? recommendedValue,
    required double? adoptedValue,
    required String unit,
    String? criterion,
  }) {
    if (recommendedValue == null || adoptedValue == null) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.insufficientData,
        code: code,
        title: 'Dados insuficientes para validar',
        message:
            'Informe o valor recomendado e o valor adotado para validar $subject.',
        criterion: criterion,
        recommendedValue: recommendedValue,
        adoptedValue: adoptedValue,
        unit: unit,
      );
    }

    if (adoptedValue < recommendedValue) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.nonCompliant,
        code: code,
        title: 'Não conforme ao critério aplicado',
        message:
            'O valor adotado para $subject é inferior ao mínimo recomendado pelo critério aplicado.',
        criterion: criterion,
        recommendedValue: recommendedValue,
        adoptedValue: adoptedValue,
        unit: unit,
      );
    }

    return TechnicalValidationResult(
      status: TechnicalValidationStatus.compliant,
      code: code,
      title: 'Conforme',
      message:
          'O valor adotado para $subject atende ao mínimo recomendado pelo critério aplicado.',
      criterion: criterion,
      recommendedValue: recommendedValue,
      adoptedValue: adoptedValue,
      unit: unit,
    );
  }

  static TechnicalValidationResult validateExactRecommendation({
    required String code,
    required String subject,
    required double? recommendedValue,
    required double? adoptedValue,
    required String unit,
    String? criterion,
  }) {
    if (recommendedValue == null || adoptedValue == null) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.insufficientData,
        code: code,
        title: 'Dados insuficientes para validar',
        message:
            'Informe o valor recomendado e o valor adotado para validar $subject.',
        criterion: criterion,
        recommendedValue: recommendedValue,
        adoptedValue: adoptedValue,
        unit: unit,
      );
    }

    if (adoptedValue != recommendedValue) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.attention,
        code: code,
        title: 'Atenção',
        message:
            'O valor adotado para $subject é diferente da recomendação calculada. Revise antes de concluir o projeto.',
        criterion: criterion,
        recommendedValue: recommendedValue,
        adoptedValue: adoptedValue,
        unit: unit,
      );
    }

    return TechnicalValidationResult(
      status: TechnicalValidationStatus.compliant,
      code: code,
      title: 'Conforme',
      message:
          'O valor adotado para $subject corresponde à recomendação calculada.',
      criterion: criterion,
      recommendedValue: recommendedValue,
      adoptedValue: adoptedValue,
      unit: unit,
    );
  }
}
