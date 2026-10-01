class ProfessionalLoad {
  static const contractVersion = 1;

  final String id;
  final String projectId;
  final int revision;
  final String name;
  final String category;
  final int quantity;
  final double powerW;
  final double voltageV;
  final double? powerFactor;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfessionalLoad({
    required this.id,
    required this.projectId,
    required this.revision,
    required this.name,
    this.category = '',
    this.quantity = 1,
    this.powerW = 0,
    this.voltageV = 0,
    this.powerFactor,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalPowerW => powerW * quantity;

  ProfessionalLoad normalized() => ProfessionalLoad(
        id: id.trim(),
        projectId: projectId.trim(),
        revision: revision < 1 ? 1 : revision,
        name: name.trim(),
        category: category.trim(),
        quantity: quantity < 1 ? 1 : quantity,
        powerW: powerW < 0 ? 0 : powerW,
        voltageV: voltageV < 0 ? 0 : voltageV,
        powerFactor: powerFactor,
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
        'category': category,
        'quantity': quantity,
        'powerW': powerW,
        'voltageV': voltageV,
        'powerFactor': powerFactor,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
