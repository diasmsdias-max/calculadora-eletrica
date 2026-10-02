import 'technical_validation.dart';

class OvercurrentProtectionValidator {
  const OvercurrentProtectionValidator._();

  static TechnicalValidationResult validate({
    required double? designCurrentA,
    required double? adoptedProtectionCurrentA,
    required double? conductorAmpacityA,
  }) {
    const criterion = 'Critério aplicado: Ib ≤ In ≤ Iz.';

    if (designCurrentA == null ||
        adoptedProtectionCurrentA == null ||
        conductorAmpacityA == null) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.insufficientData,
        code: 'protection.overcurrent.ib_in_iz',
        title: 'Dados insuficientes para validar',
        message:
            'Informe Ib, a corrente adotada da proteção (In) e a capacidade de condução do condutor (Iz).',
        criterion: criterion,
        calculatedValue: designCurrentA,
        adoptedValue: adoptedProtectionCurrentA,
        recommendedValue: null,
        unit: 'A',
      );
    }

    if (adoptedProtectionCurrentA < designCurrentA) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.nonCompliant,
        code: 'protection.overcurrent.ib_in_iz',
        title: 'Proteção abaixo da corrente de projeto',
        message:
            'A corrente adotada da proteção (In) é menor que a corrente de projeto (Ib).',
        criterion: criterion,
        calculatedValue: designCurrentA,
        adoptedValue: adoptedProtectionCurrentA,
        unit: 'A',
      );
    }

    if (adoptedProtectionCurrentA > conductorAmpacityA) {
      return TechnicalValidationResult(
        status: TechnicalValidationStatus.nonCompliant,
        code: 'protection.overcurrent.ib_in_iz',
        title: 'Proteção acima da capacidade do condutor',
        message:
            'A corrente adotada da proteção (In) é maior que a capacidade de condução do condutor (Iz).',
        criterion: criterion,
        calculatedValue: designCurrentA,
        adoptedValue: adoptedProtectionCurrentA,
        unit: 'A',
      );
    }

    return TechnicalValidationResult(
      status: TechnicalValidationStatus.compliant,
      code: 'protection.overcurrent.ib_in_iz',
      title: 'Conforme ao critério aplicado',
      message: 'A corrente adotada atende à relação Ib ≤ In ≤ Iz.',
      criterion: criterion,
      calculatedValue: designCurrentA,
      adoptedValue: adoptedProtectionCurrentA,
      unit: 'A',
    );
  }
}
