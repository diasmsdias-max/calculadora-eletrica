enum ProjectRecordType {
  motor,
  transformer,
  motorTransformer,
  loadSurvey,
  cableSizing,
  voltageDrop,
}

class ProjectRecord {
  final String id;
  final String projectId;
  final ProjectRecordType type;
  final String title;
  final String summary;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const ProjectRecord({
    required this.id,
    required this.projectId,
    required this.type,
    required this.title,
    required this.summary,
    required this.data,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'type': type.name,
    'title': title,
    'summary': summary,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProjectRecord.fromJson(Map<String, dynamic> json) => ProjectRecord(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    type: ProjectRecordType.values.byName(json['type'] as String),
    title: json['title'] as String,
    summary: json['summary'] as String? ?? '',
    data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
