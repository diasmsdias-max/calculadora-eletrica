enum QuickAmpacityMaterial { copper, aluminum }

abstract final class QuickAmpacityReference {
  static final _copperB1TwoLoaded = <double, double>{
    1.5: 17.5, 2.5: 24, 4: 32, 6: 41, 10: 57, 16: 76,
    25: 101, 35: 125, 50: 151, 70: 192, 95: 232, 120: 269,
    150: 309, 185: 353, 240: 415, 300: 477,
  };

  static final _aluminumB1TwoLoaded = <double, double>{
    16: 60, 25: 79, 35: 97, 50: 118, 70: 150, 95: 181,
    120: 210, 150: 241, 185: 275, 240: 324, 300: 372,
  };

  static double? ampacityA({
    required QuickAmpacityMaterial material,
    required double sectionMm2,
  }) {
    final table = material == QuickAmpacityMaterial.copper
        ? _copperB1TwoLoaded
        : _aluminumB1TwoLoaded;
    return table[sectionMm2];
  }
}
