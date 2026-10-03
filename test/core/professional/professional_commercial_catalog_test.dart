import 'package:flutter_test/flutter_test.dart';

import 'package:calculadora_eletrica/core/professional/professional_commercial_catalog.dart';

void main() {
  test('selects first commercial breaker current at or above Ib', () {
    expect(ProfessionalCommercialCatalog.firstBreakerAtOrAbove(15.8), 16);
    expect(ProfessionalCommercialCatalog.firstBreakerAtOrAbove(16), 16);
    expect(ProfessionalCommercialCatalog.firstBreakerAtOrAbove(16.1), 20);
  });

  test('does not invent breaker rating outside catalog', () {
    expect(ProfessionalCommercialCatalog.firstBreakerAtOrAbove(130), isNull);
    expect(ProfessionalCommercialCatalog.firstBreakerAtOrAbove(null), isNull);
    expect(ProfessionalCommercialCatalog.firstBreakerAtOrAbove(0), isNull);
  });

  test('selects first commercial conductor section at or above minimum', () {
    expect(ProfessionalCommercialCatalog.firstConductorSectionAtOrAbove(2.1), 2.5);
    expect(ProfessionalCommercialCatalog.firstConductorSectionAtOrAbove(6), 6);
    expect(ProfessionalCommercialCatalog.firstConductorSectionAtOrAbove(200), 240);
  });
}
