class ProfessionalLoad {
  static const contractVersion = 2;

  final String id;
  final String projectId;
  final int revision;
  final String name;
  final String category;
  final int quantity;
  final double powerW;
  final double voltageV;
  final double? powerFactor;
  final double? simultaneityFactor;
  final String? simultaneitySource;
  final String simultaneityBasis;
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
    this.simultaneityFactor,
    this.simultaneitySource,
    this.simultaneityBasis = '',
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
        simultaneityFactor: simultaneityFactor,
        simultaneitySource: simultaneitySource?.trim(),
        simultaneityBasis: simultaneityBasis.trim(),
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
        'simultaneityFactor': simultaneityFactor,
        'simultaneitySource': simultaneitySource,
        'simultaneityBasis': simultaneityBasis,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
  factory ProfessionalLoad.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalLoad(id:j['id'] as String,projectId:j['projectId'] as String,revision:j['revision'] as int,name:j['name'] as String,category:j['category'] as String? ?? '',quantity:j['quantity'] as int,powerW:(j['powerW'] as num).toDouble(),voltageV:(j['voltageV'] as num).toDouble(),powerFactor:(j['powerFactor'] as num?)?.toDouble(),simultaneityFactor:(j['simultaneityFactor'] as num?)?.toDouble(),simultaneitySource:j['simultaneitySource'] as String?,simultaneityBasis:j['simultaneityBasis'] as String? ?? '',notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){final v=j['contractVersion'];if(v!=1&&v!=contractVersion)throw const FormatException('Unsupported professional load contract.');}
}
