import '../licensing/license_state.dart';
import 'professional_profile.dart';

class BrandIdentity {
  static const productName = 'VIS ELECTRICA';
  static const defaultOwnerName = 'BOECKER';

  final String ownerName;
  final String productNameLabel;
  final String? document;
  final String? phone;
  final bool isProfessional;

  const BrandIdentity({
    required this.ownerName,
    required this.productNameLabel,
    this.document,
    this.phone,
    required this.isProfessional,
  });

  factory BrandIdentity.resolve({
    required LicenseState license,
    ProfessionalProfile? profile,
  }) {
    final normalized = profile?.normalized();
    final useProfessional =
        license.hasProfessional && normalized?.isConfigured == true;

    return BrandIdentity(
      ownerName:
          useProfessional ? normalized!.companyName : defaultOwnerName,
      productNameLabel: productName,
      document: useProfessional ? normalized!.document : null,
      phone: useProfessional ? normalized!.phone : null,
      isProfessional: useProfessional,
    );
  }
}
