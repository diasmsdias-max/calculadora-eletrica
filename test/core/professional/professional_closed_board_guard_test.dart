import 'package:flutter_test/flutter_test.dart';
import 'package:calculadora_eletrica/core/professional/professional_board.dart';
import 'package:calculadora_eletrica/core/professional/professional_board_repository.dart';
import 'package:calculadora_eletrica/core/professional/professional_closed_board_guard.dart';

class _Repo implements ProfessionalBoardRepository {
  final List<ProfessionalBoard> boards;
  final Map<String, List<String>> links;
  _Repo(this.boards, this.links);
  @override Future<List<ProfessionalBoard>> getByProject(String projectId) async => boards.where((b)=>b.projectId==projectId).toList();
  @override Future<List<String>> getCircuitIds(String boardId) async => links[boardId] ?? const [];
  @override Future<ProfessionalBoard?> getById(String id) async => null;
  @override Future<void> save(ProfessionalBoard board) async {}
  @override Future<void> delete(String id) async {}
  @override Future<void> replaceCircuits(String boardId, Iterable<String> circuitIds) async {}
}

void main() {
  test('locks only circuits linked to closed boards', () async {
    final t=DateTime.utc(2026,10,4);
    final repo=_Repo([
      ProfessionalBoard(id:'open',projectId:'p',revision:1,name:'QA',createdAt:t,updatedAt:t),
      ProfessionalBoard(id:'closed',projectId:'p',revision:1,name:'QF',status:ProfessionalBoardStatus.closed,closedAt:t,createdAt:t,updatedAt:t),
    ], {'open':['c1'],'closed':['c2','c3']});
    final ids=await const ProfessionalClosedBoardGuard().lockedCircuitIds(boardsRepository:repo,projectId:'p');
    expect(ids, {'c2','c3'});
  });
}
