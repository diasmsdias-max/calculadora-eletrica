class ProfessionalProfile {
  final String companyName;
  final String? document;
  final String? phone;

  const ProfessionalProfile({
    required this.companyName,
    this.document,
    this.phone,
  });

  bool get isConfigured => companyName.trim().isNotEmpty;

  ProfessionalProfile normalized() => ProfessionalProfile(
        companyName: companyName.trim(),
        document: _optional(document),
        phone: _optional(phone),
      );

  Map<String, Object?> toJson() => {
        'companyName': companyName,
        'document': document,
        'phone': phone,
      };

  factory ProfessionalProfile.fromJson(Map<String, Object?> json) =>
      ProfessionalProfile(
        companyName: (json['companyName'] as String?) ?? '',
        document: json['document'] as String?,
        phone: json['phone'] as String?,
      );

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
