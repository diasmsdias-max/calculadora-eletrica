class ProfessionalProject {
  static const contractVersion = 1;

  final String id;
  final int revision;
  final String name;
  final String client;
  final String address;
  final String responsible;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfessionalProject({
    required this.id,
    required this.revision,
    required this.name,
    this.client = '',
    this.address = '',
    this.responsible = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  ProfessionalProject normalized() => ProfessionalProject(
        id: id.trim(),
        revision: revision < 1 ? 1 : revision,
        name: name.trim(),
        client: client.trim(),
        address: address.trim(),
        responsible: responsible.trim(),
        notes: notes.trim(),
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
      );

  Map<String, Object?> toPortableJson() => {
        'contractVersion': contractVersion,
        'id': id,
        'revision': revision,
        'name': name,
        'client': client,
        'address': address,
        'responsible': responsible,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ProfessionalProject.fromPortableJson(Map<String, Object?> json) {
    if (json['contractVersion'] != contractVersion) {
      throw const FormatException('Unsupported professional project contract.');
    }
    return ProfessionalProject(
      id: json['id'] as String,
      revision: json['revision'] as int,
      name: json['name'] as String,
      client: json['client'] as String? ?? '',
      address: json['address'] as String? ?? '',
      responsible: json['responsible'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    ).normalized();
  }

  ProfessionalProject copyWith({
    String? name,
    String? client,
    String? address,
    String? responsible,
    String? notes,
    DateTime? updatedAt,
    bool incrementRevision = true,
  }) => ProfessionalProject(
        id: id,
        revision: incrementRevision ? revision + 1 : revision,
        name: name ?? this.name,
        client: client ?? this.client,
        address: address ?? this.address,
        responsible: responsible ?? this.responsible,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      ).normalized();
}
