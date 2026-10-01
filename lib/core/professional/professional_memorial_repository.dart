import 'professional_memorial.dart';
abstract interface class ProfessionalMemorialRepository {
 Future<ProfessionalMemorial?> getByProject(String projectId);
 Future<void> save(ProfessionalMemorial memorial);
 Future<void> deleteByProject(String projectId);
}
