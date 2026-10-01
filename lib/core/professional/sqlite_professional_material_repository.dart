import 'package:sqflite/sqflite.dart';
import 'professional_material.dart';
import 'professional_material_repository.dart';
class SqliteProfessionalMaterialRepository implements ProfessionalMaterialRepository {
 final Database database; const SqliteProfessionalMaterialRepository(this.database);
 @override Future<List<ProfessionalMaterial>> getByProject(String projectId) async=>
  (await database.query('professional_materials',where:'project_id = ?',whereArgs:[projectId],
   orderBy:'category COLLATE NOCASE, description COLLATE NOCASE')).map(_fromRow).toList();
 @override Future<ProfessionalMaterial?> getById(String id)async{final r=await database.query(
  'professional_materials',where:'id = ?',whereArgs:[id],limit:1);return r.isEmpty?null:_fromRow(r.single);}
 @override Future<void> save(ProfessionalMaterial material)async{final m=material.normalized();
  if(m.id.isEmpty||m.projectId.isEmpty||m.description.isEmpty)throw ArgumentError('Material id, project id and description are required.');
  if(m.quantity!=null&&m.quantity!<=0)throw ArgumentError('Material quantity must be positive.');
  final projects=await database.query('professional_projects',columns:['id'],where:'id = ?',whereArgs:[m.projectId],limit:1);
  if(projects.isEmpty)throw ArgumentError('Material project does not exist.');
  final row={'id':m.id,'project_id':m.projectId,'contract_version':ProfessionalMaterial.contractVersion,
   'revision':m.revision,'description':m.description,'category':m.category,'unit':m.unit,'quantity':m.quantity,
   'source':m.source,'notes':m.notes,'created_at':m.createdAt.toIso8601String(),'updated_at':m.updatedAt.toIso8601String()};
  final n=await database.update('professional_materials',row,where:'id = ?',whereArgs:[m.id]);
  if(n==0)await database.insert('professional_materials',row);
 }
 @override Future<void> delete(String id)=>database.delete('professional_materials',where:'id = ?',whereArgs:[id]);
 ProfessionalMaterial _fromRow(Map<String,Object?> r)=>ProfessionalMaterial(id:r['id']! as String,
  projectId:r['project_id']! as String,revision:r['revision']! as int,description:r['description']! as String,
  category:r['category'] as String? ?? '',unit:r['unit'] as String? ?? '',
  quantity:(r['quantity'] as num?)?.toDouble(),source:r['source'] as String? ?? '',notes:r['notes'] as String? ?? '',
  createdAt:DateTime.parse(r['created_at']! as String),updatedAt:DateTime.parse(r['updated_at']! as String)).normalized();
}
