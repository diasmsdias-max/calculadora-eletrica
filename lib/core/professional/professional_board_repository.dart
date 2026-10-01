import 'professional_board.dart';
abstract interface class ProfessionalBoardRepository {
  Future<List<ProfessionalBoard>> getByProject(String projectId);
  Future<ProfessionalBoard?> getById(String id);
  Future<void> save(ProfessionalBoard board);
  Future<void> delete(String id);
  Future<List<String>> getCircuitIds(String boardId);
  Future<void> replaceCircuits(String boardId, Iterable<String> circuitIds);
}
