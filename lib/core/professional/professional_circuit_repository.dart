import 'professional_circuit.dart';

abstract interface class ProfessionalCircuitRepository {
  Future<List<ProfessionalCircuit>> getByProject(String projectId);
  Future<ProfessionalCircuit?> getById(String id);
  Future<void> save(ProfessionalCircuit circuit);
  Future<void> delete(String id);
  Future<List<String>> getLoadIds(String circuitId);
  Future<void> replaceLoads(String circuitId, Iterable<String> loadIds);
}
