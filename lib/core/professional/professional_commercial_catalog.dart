class ProfessionalCommercialCatalog {
  const ProfessionalCommercialCatalog._();

  /// Commercial conductor sections commonly available in Brazil.
  ///
  /// This is a commercial-size catalog, not an ampacity table. Iz depends on
  /// conductor material, insulation, installation method, ambient conditions,
  /// grouping and other design criteria.
  static const conductorSectionsMm2 = <double>[
    1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240,
  ];

  /// Common nominal currents for low-voltage circuit breakers.
  ///
  /// The catalog only normalizes commercially available choices. A value is
  /// not a technical recommendation until the VIS engine validates Ib <= In <= Iz.
  static const breakerRatedCurrentsA = <double>[
    2, 4, 6, 10, 16, 20, 25, 32, 40, 50, 63, 80, 100, 125,
  ];

  static const breakerTripCurves = <String>['B', 'C', 'D'];

  static const breakerPoles = <int>[1, 2, 3, 4];

  static double? firstBreakerAtOrAbove(double? designCurrentA) {
    if (designCurrentA == null || designCurrentA <= 0) return null;
    for (final current in breakerRatedCurrentsA) {
      if (current >= designCurrentA) return current;
    }
    return null;
  }

  static double? firstConductorSectionAtOrAbove(double? minimumSectionMm2) {
    if (minimumSectionMm2 == null || minimumSectionMm2 <= 0) return null;
    for (final section in conductorSectionsMm2) {
      if (section >= minimumSectionMm2) return section;
    }
    return null;
  }
}
