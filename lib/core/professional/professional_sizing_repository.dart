import 'professional_sizing.dart';
abstract interface class ProfessionalSizingRepository {
  Future<List<ProfessionalSizing>> getByProject(String projectId);
  Future<ProfessionalSizing?> getByCircuit(String circuitId);
  Future<void> save(ProfessionalSizing sizing);
  Future<void> deleteByCircuit(String circuitId);
}
