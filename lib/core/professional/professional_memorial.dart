class ProfessionalMemorial {
  static const contractVersion = 1;
  final String id, projectId, title, scope, criteria, conclusions, notes;
  final int revision; final DateTime createdAt, updatedAt;
  const ProfessionalMemorial({required this.id,required this.projectId,required this.revision,
    this.title='',this.scope='',this.criteria='',this.conclusions='',this.notes='',
    required this.createdAt,required this.updatedAt});
  ProfessionalMemorial normalized()=>ProfessionalMemorial(id:id.trim(),projectId:projectId.trim(),
    revision:revision<1?1:revision,title:title.trim(),scope:scope.trim(),criteria:criteria.trim(),
    conclusions:conclusions.trim(),notes:notes.trim(),createdAt:createdAt.toUtc(),updatedAt:updatedAt.toUtc());
  Map<String,Object?> toPortableJson()=>{'contractVersion':contractVersion,'id':id,'projectId':projectId,
    'revision':revision,'title':title,'scope':scope,'criteria':criteria,'conclusions':conclusions,
    'notes':notes,'createdAt':createdAt.toUtc().toIso8601String(),'updatedAt':updatedAt.toUtc().toIso8601String()};
  factory ProfessionalMemorial.fromPortableJson(Map<String,Object?> j){_contract(j);return ProfessionalMemorial(id:j['id'] as String,projectId:j['projectId'] as String,revision:j['revision'] as int,title:j['title'] as String? ?? '',scope:j['scope'] as String? ?? '',criteria:j['criteria'] as String? ?? '',conclusions:j['conclusions'] as String? ?? '',notes:j['notes'] as String? ?? '',createdAt:DateTime.parse(j['createdAt'] as String),updatedAt:DateTime.parse(j['updatedAt'] as String)).normalized();}
  static void _contract(Map<String,Object?> j){if(j['contractVersion']!=contractVersion)throw const FormatException('Unsupported professional memorial contract.');}
}
