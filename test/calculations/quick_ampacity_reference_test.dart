import 'package:calculadora_eletrica/core/calculations/quick_ampacity_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuickAmpacityReference', () {
    test('retorna referência rápida de cobre para seções conhecidas', () {
      expect(
        QuickAmpacityReference.ampacityA(
          material: QuickAmpacityMaterial.copper,
          sectionMm2: 6,
        ),
        41,
      );
      expect(
        QuickAmpacityReference.ampacityA(
          material: QuickAmpacityMaterial.copper,
          sectionMm2: 16,
        ),
        76,
      );
    });

    test('retorna referência rápida de alumínio para seções conhecidas', () {
      expect(
        QuickAmpacityReference.ampacityA(
          material: QuickAmpacityMaterial.aluminum,
          sectionMm2: 16,
        ),
        60,
      );
      expect(
        QuickAmpacityReference.ampacityA(
          material: QuickAmpacityMaterial.aluminum,
          sectionMm2: 70,
        ),
        150,
      );
    });

    test('retorna nulo quando a seção não existe na referência rápida', () {
      expect(
        QuickAmpacityReference.ampacityA(
          material: QuickAmpacityMaterial.aluminum,
          sectionMm2: 6,
        ),
        isNull,
      );
      expect(
        QuickAmpacityReference.ampacityA(
          material: QuickAmpacityMaterial.copper,
          sectionMm2: 7,
        ),
        isNull,
      );
    });
  });
}
