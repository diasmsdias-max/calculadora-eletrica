import 'package:calculadora_eletrica/core/professional/professional_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes profile fields', () {
    const profile = ProfessionalProfile(
      companyName: '  Elétrica São José  ',
      document: '  12.345.678/0001-90  ',
      phone: '   ',
    );

    final normalized = profile.normalized();

    expect(normalized.companyName, 'Elétrica São José');
    expect(normalized.document, '12.345.678/0001-90');
    expect(normalized.phone, isNull);
  });

  test('malformed JSON fields do not crash profile restore', () {
    final profile = ProfessionalProfile.fromJson({
      'companyName': 123,
      'document': <String>['invalid'],
      'phone': true,
    });

    expect(profile.companyName, isEmpty);
    expect(profile.document, isNull);
    expect(profile.phone, isNull);
    expect(profile.isConfigured, isFalse);
  });
}
