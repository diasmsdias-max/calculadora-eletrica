import 'professional_project.dart';

abstract interface class ProfessionalProjectRepository {
  Future<List<ProfessionalProject>> getAll();
  Future<ProfessionalProject?> getById(String id);
  Future<void> save(ProfessionalProject project);
  Future<void> delete(String id);
}
