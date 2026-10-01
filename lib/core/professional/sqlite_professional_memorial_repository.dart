import 'package:sqflite/sqflite.dart';
import 'professional_memorial.dart';
import 'professional_memorial_repository.dart';
class SqliteProfessionalMemorialRepository implements ProfessionalMemorialRepository {
 final Database database; const SqliteProfessionalMemorialRepository(this.database);
 @override Future<ProfessionalMemorial?> getByProject(String projectId)async{
  final r=await database.query('professional_memorials',where:'project_id = ?',whereArgs:[projectId],limit:1);
  return r.isEmpty?null:_fromRow(r.single);
 }
 @override Future<void> save(ProfessionalMemorial memorial)async{final m=memorial.normalized();
  if(m.id.isEmpty||m.projectId.isEmpty)throw ArgumentError('Memorial id and project id are required.');
  final projects=await database.query('professional_projects',columns:['id'],where:'id = ?',whereArgs:[m.projectId],limit:1);
  if(projects.isEmpty)throw ArgumentError('Memorial project does not exist.');
  final row={'id':m.id,'project_id':m.projectId,'contract_version':ProfessionalMemorial.contractVersion,
   'revision':m.revision,'title':m.title,'scope':m.scope,'criteria':m.criteria,'conclusions':m.conclusions,
   'notes':m.notes,'created_at':m.createdAt.toIso8601String(),'updated_at':m.updatedAt.toIso8601String()};
  final n=await database.update('professional_memorials',row,where:'id = ?',whereArgs:[m.id]);
  if(n==0)await database.insert('professional_memorials',row);
 }
 @override Future<void> deleteByProject(String projectId)=>database.delete('professional_memorials',
  where:'project_id = ?',whereArgs:[projectId]);
 ProfessionalMemorial _fromRow(Map<String,Object?> r)=>ProfessionalMemorial(id:r['id']! as String,
  projectId:r['project_id']! as String,revision:r['revision']! as int,title:r['title'] as String? ?? '',
  scope:r['scope'] as String? ?? '',criteria:r['criteria'] as String? ?? '',
  conclusions:r['conclusions'] as String? ?? '',notes:r['notes'] as String? ?? '',
  createdAt:DateTime.parse(r['created_at']! as String),updatedAt:DateTime.parse(r['updated_at']! as String)).normalized();
}
