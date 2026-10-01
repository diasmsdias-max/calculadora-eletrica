class ProfessionalCircuit {
  static const contractVersion = 1;

  final String id;
  final String projectId;
  final int revision;
  final String name;
  final String description;
  final double? voltageV;
  final int? phases;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfessionalCircuit({
    required this.id,
    required this.projectId,
    required this.revision,
    required this.name,
    this.description = '',
    this.voltageV,
    this.phases,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  ProfessionalCircuit normalized() => ProfessionalCircuit(
        id: id.trim(),
        projectId: projectId.trim(),
        revision: revision < 1 ? 1 : revision,
        name: name.trim(),
        description: description.trim(),
        voltageV: voltageV,
        phases: phases,
        notes: notes.trim(),
        createdAt: createdAt.toUtc(),
        updatedAt: updatedAt.toUtc(),
      );

  Map<String, Object?> toPortableJson() => {
        'contractVersion': contractVersion,
        'id': id,
        'projectId': projectId,
        'revision': revision,
        'name': name,
        'description': description,
        'voltageV': voltageV,
        'phases': phases,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
  factory ProfessionalCircuit.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalCircuit(id:j['id'] as String,projectId:j['projectId'] as String,revision:j['revision'] as int,name:j['name'] as String,description:j['description'] as String? ?? '',voltageV:(j['voltageV'] as num?)?.toDouble(),phases:j['phases'] as int?,notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){if(j['contractVersion']!=contractVersion)throw const FormatException('Unsupported professional circuit contract.');}
}
