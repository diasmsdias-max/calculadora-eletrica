enum QuickAmpacityMaterial { copper, aluminum }

abstract final class QuickAmpacityReference {
  static const referenceDescription =
      'PVC 70 C - metodo B1';

  static int loadedConductorsForSystemName(String systemName) =>
      systemName == 'threePhase' ? 3 : 2;
  static final _copperB1TwoLoaded = <double, double>{
    1.5: 17.5, 2.5: 24, 4: 32, 6: 41, 10: 57, 16: 76,
    25: 101, 35: 125, 50: 151, 70: 192, 95: 232, 120: 269,
    150: 309, 185: 353, 240: 415, 300: 477,
  };

  static final _copperB1ThreeLoaded = <double, double>{
    1.5: 15.5, 2.5: 21, 4: 28, 6: 36, 10: 50, 16: 68,
    25: 89, 35: 110, 50: 134, 70: 171, 95: 207, 120: 239,
    150: 275, 185: 314, 240: 370, 300: 426,
  };

  static final _aluminumB1ThreeLoaded = <double, double>{
    16: 53, 25: 70, 35: 86, 50: 104, 70: 133, 95: 161,
    120: 186, 150: 214, 185: 245, 240: 288, 300: 331,
  };

  static final _aluminumB1TwoLoaded = <double, double>{
    16: 60, 25: 79, 35: 97, 50: 118, 70: 150, 95: 181,
    120: 210, 150: 241, 185: 275, 240: 324, 300: 372,
  };

  static double? ampacityA({
    required QuickAmpacityMaterial material,
    required double sectionMm2,
    int loadedConductors = 2,
  }) {
    if (loadedConductors != 2 && loadedConductors != 3) {
      throw ArgumentError.value(loadedConductors, 'loadedConductors', 'use 2 or 3');
    }
    if (material == QuickAmpacityMaterial.copper) {
      return (loadedConductors == 3 ? _copperB1ThreeLoaded : _copperB1TwoLoaded)[sectionMm2];
    }
    return (loadedConductors == 3
        ? _aluminumB1ThreeLoaded
        : _aluminumB1TwoLoaded)[sectionMm2];
  }
}
