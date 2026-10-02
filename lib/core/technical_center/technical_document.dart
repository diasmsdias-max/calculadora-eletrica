enum TechnicalDocumentCategory { manufacturerManual, controlPanel, technicalReference, other }
enum TechnicalDocumentAvailability { remoteOnly, downloaded, bundled }

class TechnicalDocument {
  static const contractVersion = 1;
  final String id, title, manufacturer, equipmentType, model, description;
  final TechnicalDocumentCategory category;
  final String remotePath, fileName, mimeType, checksum;
  final int? sizeBytes;
  final TechnicalDocumentAvailability availability;
  final String? localPath;
  final bool keepOffline;
  final DateTime? publishedAt, downloadedAt, updatedAt;

  const TechnicalDocument({
    required this.id, required this.title, required this.category,
    this.manufacturer='', this.equipmentType='', this.model='', this.description='',
    this.remotePath='', this.fileName='', this.mimeType='application/pdf',
    this.checksum='', this.sizeBytes, this.availability=TechnicalDocumentAvailability.remoteOnly,
    this.localPath, this.keepOffline=false, this.publishedAt, this.downloadedAt, this.updatedAt,
  });

  bool get isAvailableOffline =>
      availability != TechnicalDocumentAvailability.remoteOnly &&
      localPath != null && localPath!.trim().isNotEmpty;

  TechnicalDocument normalized()=>TechnicalDocument(
    id:id.trim(),title:title.trim(),category:category,manufacturer:manufacturer.trim(),
    equipmentType:equipmentType.trim(),model:model.trim(),description:description.trim(),
    remotePath:remotePath.trim(),fileName:fileName.trim(),mimeType:mimeType.trim(),
    checksum:checksum.trim(),sizeBytes:sizeBytes,availability:availability,
    localPath:localPath?.trim(),keepOffline:keepOffline,publishedAt:publishedAt?.toUtc(),
    downloadedAt:downloadedAt?.toUtc(),updatedAt:updatedAt?.toUtc(),
  );

  Map<String,Object?> toPortableJson()=>{
    'contractVersion':contractVersion,'id':id,'title':title,'category':category.name,
    'manufacturer':manufacturer,'equipmentType':equipmentType,'model':model,
    'description':description,'remotePath':remotePath,'fileName':fileName,
    'mimeType':mimeType,'checksum':checksum,'sizeBytes':sizeBytes,
    'availability':availability.name,'localPath':localPath,'keepOffline':keepOffline,
    'publishedAt':publishedAt?.toUtc().toIso8601String(),
    'downloadedAt':downloadedAt?.toUtc().toIso8601String(),
    'updatedAt':updatedAt?.toUtc().toIso8601String(),
  };

  factory TechnicalDocument.fromPortableJson(Map<String,Object?> j){
    if(j['contractVersion']!=contractVersion) throw const FormatException('Unsupported technical document contract.');
    return TechnicalDocument(
      id:j['id'] as String,title:j['title'] as String,
      category:TechnicalDocumentCategory.values.byName(j['category'] as String),
      manufacturer:j['manufacturer'] as String? ?? '',equipmentType:j['equipmentType'] as String? ?? '',
      model:j['model'] as String? ?? '',description:j['description'] as String? ?? '',
      remotePath:j['remotePath'] as String? ?? '',fileName:j['fileName'] as String? ?? '',
      mimeType:j['mimeType'] as String? ?? 'application/pdf',checksum:j['checksum'] as String? ?? '',
      sizeBytes:j['sizeBytes'] as int?,availability:TechnicalDocumentAvailability.values.byName(j['availability'] as String? ?? 'remoteOnly'),
      localPath:j['localPath'] as String?,keepOffline:j['keepOffline'] as bool? ?? false,
      publishedAt:_date(j['publishedAt']),downloadedAt:_date(j['downloadedAt']),updatedAt:_date(j['updatedAt']),
    ).normalized();
  }
  static DateTime? _date(Object? v)=>v is String&&v.isNotEmpty?DateTime.parse(v):null;
}
