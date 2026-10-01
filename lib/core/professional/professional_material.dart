class ProfessionalMaterial {
  static const contractVersion = 1;
  final String id, projectId, description, category, unit, source, notes;
  final int revision; final double? quantity; final DateTime createdAt, updatedAt;
  const ProfessionalMaterial({required this.id,required this.projectId,required this.revision,
    required this.description,this.category='',this.unit='',this.quantity,this.source='',this.notes='',
    required this.createdAt,required this.updatedAt});
  ProfessionalMaterial normalized()=>ProfessionalMaterial(id:id.trim(),projectId:projectId.trim(),
    revision:revision<1?1:revision,description:description.trim(),category:category.trim(),unit:unit.trim(),
    quantity:quantity,source:source.trim(),notes:notes.trim(),createdAt:createdAt.toUtc(),updatedAt:updatedAt.toUtc());
  Map<String,Object?> toPortableJson()=>{'contractVersion':contractVersion,'id':id,'projectId':projectId,
    'revision':revision,'description':description,'category':category,'unit':unit,'quantity':quantity,
    'source':source,'notes':notes,'createdAt':createdAt.toUtc().toIso8601String(),
    'updatedAt':updatedAt.toUtc().toIso8601String()};
}
