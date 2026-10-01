import 'professional_load.dart';

abstract interface class ProfessionalLoadRepository {
  Future<List<ProfessionalLoad>> getByProject(String projectId);
  Future<ProfessionalLoad?> getById(String id);
  Future<void> save(ProfessionalLoad load);
  Future<void> delete(String id);
}
