class ProfessionalSizing {
  static const contractVersion = 1;
  final String id, projectId, circuitId, method, criteria, notes;
  final int revision;
  final double? designCurrentA, conductorSectionMm2, conductorAmpacityA, voltageDropPercent, protectionCurrentA;
  final DateTime createdAt, updatedAt;

  const ProfessionalSizing({
    required this.id, required this.projectId, required this.circuitId, required this.revision,
    this.designCurrentA, this.conductorSectionMm2, this.conductorAmpacityA, this.voltageDropPercent,
    this.protectionCurrentA, this.method='', this.criteria='', this.notes='',
    required this.createdAt, required this.updatedAt,
  });

  ProfessionalSizing normalized()=>ProfessionalSizing(
    id:id.trim(),projectId:projectId.trim(),circuitId:circuitId.trim(),revision:revision<1?1:revision,
    designCurrentA:designCurrentA,conductorSectionMm2:conductorSectionMm2,
    conductorAmpacityA:conductorAmpacityA,voltageDropPercent:voltageDropPercent,protectionCurrentA:protectionCurrentA,
    method:method.trim(),criteria:criteria.trim(),notes:notes.trim(),
    createdAt:createdAt.toUtc(),updatedAt:updatedAt.toUtc());

  Map<String,Object?> toPortableJson()=>{
    'contractVersion':contractVersion,'id':id,'projectId':projectId,'circuitId':circuitId,
    'revision':revision,'designCurrentA':designCurrentA,'conductorSectionMm2':conductorSectionMm2,
    'conductorAmpacityA':conductorAmpacityA,'voltageDropPercent':voltageDropPercent,'protectionCurrentA':protectionCurrentA,
    'method':method,'criteria':criteria,'notes':notes,
    'createdAt':createdAt.toUtc().toIso8601String(),'updatedAt':updatedAt.toUtc().toIso8601String()
  };
  factory ProfessionalSizing.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalSizing(id:j['id'] as String,projectId:j['projectId'] as String,circuitId:j['circuitId'] as String,revision:j['revision'] as int,designCurrentA:(j['designCurrentA'] as num?)?.toDouble(),conductorSectionMm2:(j['conductorSectionMm2'] as num?)?.toDouble(),conductorAmpacityA:(j['conductorAmpacityA'] as num?)?.toDouble(),voltageDropPercent:(j['voltageDropPercent'] as num?)?.toDouble(),protectionCurrentA:(j['protectionCurrentA'] as num?)?.toDouble(),method:j['method'] as String? ?? '',criteria:j['criteria'] as String? ?? '',notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){if(j['contractVersion']!=contractVersion)throw const FormatException('Unsupported professional sizing contract.');}
}
