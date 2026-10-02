import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/overcurrent_protection_validator.dart';
import 'package:calculadora_eletrica/core/professional/technical_validation.dart';

void main() {
  test('requires Ib In and Iz', () {
    final result = OvercurrentProtectionValidator.validate(
      designCurrentA: 18,
      adoptedProtectionCurrentA: 20,
      conductorAmpacityA: null,
    );
    expect(result.status, TechnicalValidationStatus.insufficientData);
  });

  test('rejects In below Ib', () {
    final result = OvercurrentProtectionValidator.validate(
      designCurrentA: 18,
      adoptedProtectionCurrentA: 16,
      conductorAmpacityA: 24,
    );
    expect(result.status, TechnicalValidationStatus.nonCompliant);
  });

  test('rejects In above Iz', () {
    final result = OvercurrentProtectionValidator.validate(
      designCurrentA: 18,
      adoptedProtectionCurrentA: 25,
      conductorAmpacityA: 24,
    );
    expect(result.status, TechnicalValidationStatus.nonCompliant);
  });

  test('accepts Ib less than or equal to In less than or equal to Iz', () {
    final result = OvercurrentProtectionValidator.validate(
      designCurrentA: 18,
      adoptedProtectionCurrentA: 20,
      conductorAmpacityA: 24,
    );
    expect(result.status, TechnicalValidationStatus.compliant);
  });

  test('accepts boundary values', () {
    final result = OvercurrentProtectionValidator.validate(
      designCurrentA: 20,
      adoptedProtectionCurrentA: 20,
      conductorAmpacityA: 20,
    );
    expect(result.status, TechnicalValidationStatus.compliant);
  });
}
