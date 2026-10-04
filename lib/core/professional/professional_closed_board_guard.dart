import 'professional_board.dart';
import 'professional_board_repository.dart';

class ProfessionalClosedBoardGuard {
  const ProfessionalClosedBoardGuard();

  Future<Set<String>> lockedCircuitIds({
    required ProfessionalBoardRepository boardsRepository,
    required String projectId,
  }) async {
    final boards = await boardsRepository.getByProject(projectId);
    final locked = <String>{};
    for (final board in boards.where((board) => board.isClosed)) {
      locked.addAll(await boardsRepository.getCircuitIds(board.id));
    }
    return locked;
  }
}
