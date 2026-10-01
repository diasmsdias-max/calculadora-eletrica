import 'professional_protection.dart';
abstract interface class ProfessionalProtectionRepository {
  Future<List<ProfessionalProtection>> getByProject(String projectId);
  Future<List<ProfessionalProtection>> getByCircuit(String circuitId);
  Future<ProfessionalProtection?> getById(String id);
  Future<void> save(ProfessionalProtection protection);
  Future<void> delete(String id);
}
