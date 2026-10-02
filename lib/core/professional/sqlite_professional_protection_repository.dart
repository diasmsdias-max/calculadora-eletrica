import 'package:sqflite/sqflite.dart';
import 'professional_protection.dart';
import 'professional_protection_repository.dart';

class SqliteProfessionalProtectionRepository implements ProfessionalProtectionRepository {
  final Database database;
  const SqliteProfessionalProtectionRepository(this.database);

  @override
  Future<List<ProfessionalProtection>> getByProject(String projectId) async =>
    (await database.query('professional_protections',where:'project_id = ?',whereArgs:[projectId],
      orderBy:'name COLLATE NOCASE')).map(_fromRow).toList();

  @override
  Future<List<ProfessionalProtection>> getByCircuit(String circuitId) async =>
    (await database.query('professional_protections',where:'circuit_id = ?',whereArgs:[circuitId],
      orderBy:'name COLLATE NOCASE')).map(_fromRow).toList();

  @override
  Future<ProfessionalProtection?> getById(String id) async {
    final rows=await database.query('professional_protections',where:'id = ?',whereArgs:[id],limit:1);
    return rows.isEmpty?null:_fromRow(rows.single);
  }

  @override
  Future<void> save(ProfessionalProtection protection) async {
    final p=protection.normalized();
    if(p.id.isEmpty||p.projectId.isEmpty||p.circuitId.isEmpty||p.name.isEmpty) {
      throw ArgumentError('Protection id, project id, circuit id and name are required.');
    }
    if(p.ratedCurrentA!=null&&p.ratedCurrentA!<=0) throw ArgumentError('Rated current must be positive.');
    if(p.recommendedCurrentA!=null&&p.recommendedCurrentA!<=0) throw ArgumentError('Recommended current must be positive.');
    if(p.poles!=null&&(p.poles!<1||p.poles!>4)) throw ArgumentError('Poles must be between 1 and 4.');
    if(p.breakingCapacityKa!=null&&p.breakingCapacityKa!<=0) throw ArgumentError('Breaking capacity must be positive.');
    final circuits=await database.query('professional_circuits',columns:['project_id'],
      where:'id = ?',whereArgs:[p.circuitId],limit:1);
    if(circuits.isEmpty||circuits.single['project_id']!=p.projectId) {
      throw ArgumentError('Protection and circuit must belong to the same project.');
    }
    final row={'id':p.id,'project_id':p.projectId,'circuit_id':p.circuitId,
      'contract_version':ProfessionalProtection.contractVersion,'revision':p.revision,'name':p.name,
      'device_type':p.deviceType,'protection_role':p.role?.name,'rated_current_a':p.ratedCurrentA,
      'recommended_current_a':p.recommendedCurrentA,'validation_status':p.validationStatus,
      'validation_criterion':p.validationCriterion,'poles':p.poles,
      'trip_curve':p.tripCurve,'breaking_capacity_ka':p.breakingCapacityKa,'notes':p.notes,
      'created_at':p.createdAt.toIso8601String(),'updated_at':p.updatedAt.toIso8601String()};
    final n=await database.update('professional_protections',row,where:'id = ?',whereArgs:[p.id]);
    if(n==0)await database.insert('professional_protections',row);
  }

  @override
  Future<void> delete(String id)=>database.delete('professional_protections',where:'id = ?',whereArgs:[id]);

  ProfessionalProtectionRole? _role(String? value){if(value==null||value.isEmpty)return null;for(final role in ProfessionalProtectionRole.values){if(role.name==value)return role;}return null;}

  ProfessionalProtection _fromRow(Map<String,Object?> r)=>ProfessionalProtection(
    id:r['id']! as String,projectId:r['project_id']! as String,circuitId:r['circuit_id']! as String,
    revision:r['revision']! as int,name:r['name']! as String,deviceType:r['device_type'] as String? ?? '',
    role:_role(r['protection_role'] as String?),
    ratedCurrentA:(r['rated_current_a'] as num?)?.toDouble(),
    recommendedCurrentA:(r['recommended_current_a'] as num?)?.toDouble(),
    validationStatus:r['validation_status'] as String? ?? '',
    validationCriterion:r['validation_criterion'] as String? ?? '',poles:r['poles'] as int?,
    tripCurve:r['trip_curve'] as String? ?? '',breakingCapacityKa:(r['breaking_capacity_ka'] as num?)?.toDouble(),
    notes:r['notes'] as String? ?? '',createdAt:DateTime.parse(r['created_at']! as String),
    updatedAt:DateTime.parse(r['updated_at']! as String)).normalized();
}
