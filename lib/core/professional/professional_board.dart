class ProfessionalBoard {
  static const contractVersion = 1;
  final String id;
  final String projectId;
  final int revision;
  final String name;
  final String description;
  final String location;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfessionalBoard({
    required this.id, required this.projectId, required this.revision,
    required this.name, this.description = '', this.location = '',
    this.notes = '', required this.createdAt, required this.updatedAt,
  });

  ProfessionalBoard normalized() => ProfessionalBoard(
    id: id.trim(), projectId: projectId.trim(), revision: revision < 1 ? 1 : revision,
    name: name.trim(), description: description.trim(), location: location.trim(),
    notes: notes.trim(), createdAt: createdAt.toUtc(), updatedAt: updatedAt.toUtc());

  Map<String, Object?> toPortableJson() => {
    'contractVersion': contractVersion, 'id': id, 'projectId': projectId,
    'revision': revision, 'name': name, 'description': description,
    'location': location, 'notes': notes,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
  factory ProfessionalBoard.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalBoard(id:j['id'] as String,projectId:j['projectId'] as String,revision:j['revision'] as int,name:j['name'] as String,description:j['description'] as String? ?? '',location:j['location'] as String? ?? '',notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){if(j['contractVersion']!=contractVersion)throw const FormatException('Unsupported professional board contract.');}
}
