class ProfessionalSizing {
  static const contractVersion = 1;
  final String id, projectId, circuitId, method, criteria, notes;
  final int revision;
  final double? designCurrentA, conductorSectionMm2, voltageDropPercent, protectionCurrentA;
  final DateTime createdAt, updatedAt;

  const ProfessionalSizing({
    required this.id, required this.projectId, required this.circuitId, required this.revision,
    this.designCurrentA, this.conductorSectionMm2, this.voltageDropPercent,
    this.protectionCurrentA, this.method='', this.criteria='', this.notes='',
    required this.createdAt, required this.updatedAt,
  });

  ProfessionalSizing normalized()=>ProfessionalSizing(
    id:id.trim(),projectId:projectId.trim(),circuitId:circuitId.trim(),revision:revision<1?1:revision,
    designCurrentA:designCurrentA,conductorSectionMm2:conductorSectionMm2,
    voltageDropPercent:voltageDropPercent,protectionCurrentA:protectionCurrentA,
    method:method.trim(),criteria:criteria.trim(),notes:notes.trim(),
    createdAt:createdAt.toUtc(),updatedAt:updatedAt.toUtc());

  Map<String,Object?> toPortableJson()=>{
    'contractVersion':contractVersion,'id':id,'projectId':projectId,'circuitId':circuitId,
    'revision':revision,'designCurrentA':designCurrentA,'conductorSectionMm2':conductorSectionMm2,
    'voltageDropPercent':voltageDropPercent,'protectionCurrentA':protectionCurrentA,
    'method':method,'criteria':criteria,'notes':notes,
    'createdAt':createdAt.toUtc().toIso8601String(),'updatedAt':updatedAt.toUtc().toIso8601String()
  };
}
