import 'professional_material.dart';
abstract interface class ProfessionalMaterialRepository {
 Future<List<ProfessionalMaterial>> getByProject(String projectId);
 Future<ProfessionalMaterial?> getById(String id);
 Future<void> save(ProfessionalMaterial material);
 Future<void> delete(String id);
 Future<void> replaceGeneratedForBoard(String projectId,String boardId,Iterable<ProfessionalMaterial> materials);
}
