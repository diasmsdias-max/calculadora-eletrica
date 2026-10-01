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
        companyName: _string(json['companyName']) ?? '',
        document: _string(json['document']),
        phone: _string(json['phone']),
      ).normalized();

  static String? _string(Object? value) => value is String ? value : null;

  static String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
