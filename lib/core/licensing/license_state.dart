enum LicenseStatus { free, active, validationRequired, inactive }

enum Entitlement { professional }

class LicenseState {
  final LicenseStatus status;
  final Set<Entitlement> entitlements;

  const LicenseState({
    this.status = LicenseStatus.free,
    this.entitlements = const <Entitlement>{},
  });

  bool has(Entitlement entitlement) =>
      status == LicenseStatus.active && entitlements.contains(entitlement);

  bool get hasProfessional => has(Entitlement.professional);

  bool get canEditProfessionalProjects => hasProfessional;

  bool get canReadProfessionalProjects => true;

  bool get canBackupData => true;
}
