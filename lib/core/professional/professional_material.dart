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
  factory ProfessionalMaterial.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalMaterial(id:j['id'] as String,projectId:j['projectId'] as String,revision:j['revision'] as int,description:j['description'] as String,category:j['category'] as String? ?? '',unit:j['unit'] as String? ?? '',quantity:(j['quantity'] as num?)?.toDouble(),source:j['source'] as String? ?? '',notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){if(j['contractVersion']!=contractVersion)throw const FormatException('Unsupported professional material contract.');}
}
