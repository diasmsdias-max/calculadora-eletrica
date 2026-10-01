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
}
