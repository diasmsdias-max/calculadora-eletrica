class LocalProject {
  final String id;
  final String name;
  final String client;
  final String address;
  final String responsible;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocalProject({
    required this.id,
    required this.name,
    required this.client,
    required this.address,
    required this.responsible,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'client': client,
    'address': address,
    'responsible': responsible,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LocalProject.fromJson(Map<String, dynamic> json) => LocalProject(
    id: json['id'] as String,
    name: json['name'] as String,
    client: json['client'] as String? ?? '',
    address: json['address'] as String? ?? '',
    responsible: json['responsible'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  LocalProject copyWith({
    String? name,
    String? client,
    String? address,
    String? responsible,
    String? notes,
    DateTime? updatedAt,
  }) => LocalProject(
    id: id,
    name: name ?? this.name,
    client: client ?? this.client,
    address: address ?? this.address,
    responsible: responsible ?? this.responsible,
    notes: notes ?? this.notes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
