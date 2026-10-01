class ProfessionalProtection {
  static const contractVersion = 1;
  final String id, projectId, circuitId, name, deviceType, tripCurve, notes;
  final int revision;
  final double? ratedCurrentA, breakingCapacityKa;
  final int? poles;
  final DateTime createdAt, updatedAt;

  const ProfessionalProtection({
    required this.id, required this.projectId, required this.circuitId,
    required this.revision, required this.name, this.deviceType='',
    this.ratedCurrentA, this.poles, this.tripCurve='', this.breakingCapacityKa,
    this.notes='', required this.createdAt, required this.updatedAt,
  });

  ProfessionalProtection normalized()=>ProfessionalProtection(
    id:id.trim(),projectId:projectId.trim(),circuitId:circuitId.trim(),
    revision:revision<1?1:revision,name:name.trim(),deviceType:deviceType.trim(),
    ratedCurrentA:ratedCurrentA,poles:poles,tripCurve:tripCurve.trim(),
    breakingCapacityKa:breakingCapacityKa,notes:notes.trim(),
    createdAt:createdAt.toUtc(),updatedAt:updatedAt.toUtc());

  Map<String,Object?> toPortableJson()=>{
    'contractVersion':contractVersion,'id':id,'projectId':projectId,'circuitId':circuitId,
    'revision':revision,'name':name,'deviceType':deviceType,'ratedCurrentA':ratedCurrentA,
    'poles':poles,'tripCurve':tripCurve,'breakingCapacityKa':breakingCapacityKa,'notes':notes,
    'createdAt':createdAt.toUtc().toIso8601String(),'updatedAt':updatedAt.toUtc().toIso8601String()
  };
  factory ProfessionalProtection.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalProtection(id:j['id'] as String,projectId:j['projectId'] as String,circuitId:j['circuitId'] as String,revision:j['revision'] as int,name:j['name'] as String,deviceType:j['deviceType'] as String? ?? '',ratedCurrentA:(j['ratedCurrentA'] as num?)?.toDouble(),poles:j['poles'] as int?,tripCurve:j['tripCurve'] as String? ?? '',breakingCapacityKa:(j['breakingCapacityKa'] as num?)?.toDouble(),notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){if(j['contractVersion']!=contractVersion)throw const FormatException('Unsupported professional protection contract.');}
}
