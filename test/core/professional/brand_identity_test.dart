import 'package:calculadora_eletrica/core/licensing/license_state.dart';
import 'package:calculadora_eletrica/core/professional/brand_identity.dart';
import 'package:calculadora_eletrica/core/professional/professional_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = ProfessionalProfile(
    companyName: 'Elétrica São José',
    document: '00.000.000/0001-00',
    phone: '(27) 99999-9999',
  );

  test('free edition always keeps BOECKER / VIS ELECTRICA', () {
    final brand = BrandIdentity.resolve(
      license: const LicenseState(),
      profile: profile,
    );

    expect(brand.ownerName, 'BOECKER');
    expect(brand.productNameLabel, 'VIS ELECTRICA');
    expect(brand.isProfessional, isFalse);
    expect(brand.document, isNull);
  });

  test('professional entitlement uses configured company identity', () {
    final brand = BrandIdentity.resolve(
      license: const LicenseState(
        status: LicenseStatus.active,
        entitlements: {Entitlement.professional},
      ),
      profile: profile,
    );

    expect(brand.ownerName, 'Elétrica São José');
    expect(brand.productNameLabel, 'VIS ELECTRICA');
    expect(brand.document, '00.000.000/0001-00');
    expect(brand.phone, '(27) 99999-9999');
    expect(brand.isProfessional, isTrue);
  });

  test('professional entitlement without profile falls back to BOECKER', () {
    final brand = BrandIdentity.resolve(
      license: const LicenseState(
        status: LicenseStatus.active,
        entitlements: {Entitlement.professional},
      ),
    );

    expect(brand.ownerName, 'BOECKER');
    expect(brand.productNameLabel, 'VIS ELECTRICA');
    expect(brand.isProfessional, isFalse);
  });

  test('read and backup remain available without active entitlement', () {
    const license = LicenseState(status: LicenseStatus.inactive);

    expect(license.canEditProfessionalProjects, isFalse);
    expect(license.canReadProfessionalProjects, isTrue);
    expect(license.canBackupData, isTrue);
  });
}
