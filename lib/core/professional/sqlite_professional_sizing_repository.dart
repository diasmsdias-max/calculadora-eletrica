import 'package:sqflite/sqflite.dart';
import 'professional_sizing.dart';
import 'professional_sizing_repository.dart';

class SqliteProfessionalSizingRepository implements ProfessionalSizingRepository {
  final Database database;
  const SqliteProfessionalSizingRepository(this.database);

  @override
  Future<List<ProfessionalSizing>> getByProject(String projectId) async =>
    (await database.query('professional_sizing',where:'project_id = ?',whereArgs:[projectId],
      orderBy:'updated_at DESC')).map(_fromRow).toList();

  @override
  Future<ProfessionalSizing?> getByCircuit(String circuitId) async {
    final rows=await database.query('professional_sizing',where:'circuit_id = ?',whereArgs:[circuitId],limit:1);
    return rows.isEmpty?null:_fromRow(rows.single);
  }

  @override
  Future<void> save(ProfessionalSizing sizing) async {
    final s=sizing.normalized();
    if(s.id.isEmpty||s.projectId.isEmpty||s.circuitId.isEmpty) {
      throw ArgumentError('Sizing id, project id and circuit id are required.');
    }
    for(final value in [s.designCurrentA,s.conductorSectionMm2,s.protectionCurrentA]) {
      if(value!=null&&value<=0) throw ArgumentError('Sizing positive values must be greater than zero.');
    }
    if(s.voltageDropPercent!=null&&(s.voltageDropPercent!<0||s.voltageDropPercent!>100)) {
      throw ArgumentError('Voltage drop percentage must be between 0 and 100.');
    }
    final circuits=await database.query('professional_circuits',columns:['project_id'],
      where:'id = ?',whereArgs:[s.circuitId],limit:1);
    if(circuits.isEmpty||circuits.single['project_id']!=s.projectId) {
      throw ArgumentError('Sizing and circuit must belong to the same project.');
    }
    final row={'id':s.id,'project_id':s.projectId,'circuit_id':s.circuitId,
      'contract_version':ProfessionalSizing.contractVersion,'revision':s.revision,
      'design_current_a':s.designCurrentA,'conductor_section_mm2':s.conductorSectionMm2,
      'voltage_drop_percent':s.voltageDropPercent,'protection_current_a':s.protectionCurrentA,
      'method':s.method,'criteria':s.criteria,'notes':s.notes,
      'created_at':s.createdAt.toIso8601String(),'updated_at':s.updatedAt.toIso8601String()};
    final n=await database.update('professional_sizing',row,where:'id = ?',whereArgs:[s.id]);
    if(n==0)await database.insert('professional_sizing',row);
  }

  @override
  Future<void> deleteByCircuit(String circuitId)=>database.delete('professional_sizing',
    where:'circuit_id = ?',whereArgs:[circuitId]);

  ProfessionalSizing _fromRow(Map<String,Object?> r)=>ProfessionalSizing(
    id:r['id']! as String,projectId:r['project_id']! as String,circuitId:r['circuit_id']! as String,
    revision:r['revision']! as int,designCurrentA:(r['design_current_a'] as num?)?.toDouble(),
    conductorSectionMm2:(r['conductor_section_mm2'] as num?)?.toDouble(),
    voltageDropPercent:(r['voltage_drop_percent'] as num?)?.toDouble(),
    protectionCurrentA:(r['protection_current_a'] as num?)?.toDouble(),
    method:r['method'] as String? ?? '',criteria:r['criteria'] as String? ?? '',
    notes:r['notes'] as String? ?? '',createdAt:DateTime.parse(r['created_at']! as String),
    updatedAt:DateTime.parse(r['updated_at']! as String)).normalized();
}
