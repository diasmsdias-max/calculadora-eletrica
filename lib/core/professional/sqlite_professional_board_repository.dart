import 'package:sqflite/sqflite.dart';
import 'professional_board.dart';
import 'professional_board_repository.dart';

class SqliteProfessionalBoardRepository implements ProfessionalBoardRepository {
  final Database database;
  const SqliteProfessionalBoardRepository(this.database);

  @override
  Future<List<ProfessionalBoard>> getByProject(String projectId) async =>
    (await database.query('professional_boards', where: 'project_id = ?',
      whereArgs: [projectId], orderBy: 'name COLLATE NOCASE')).map(_fromRow).toList();

  @override
  Future<ProfessionalBoard?> getById(String id) async {
    final rows = await database.query('professional_boards', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.single);
  }

  @override
  Future<void> save(ProfessionalBoard board) async {
    final b = board.normalized();
    if (b.id.isEmpty || b.projectId.isEmpty || b.name.isEmpty) {
      throw ArgumentError('Board id, project id and name are required.');
    }
    final row = {'id':b.id,'project_id':b.projectId,'contract_version':ProfessionalBoard.contractVersion,
      'revision':b.revision,'name':b.name,'description':b.description,'location':b.location,
      'notes':b.notes,'status':b.status.name,'closed_at':b.closedAt?.toIso8601String(),
      'created_at':b.createdAt.toIso8601String(),'updated_at':b.updatedAt.toIso8601String()};
    final updated = await database.update('professional_boards', row, where: 'id = ?', whereArgs: [b.id]);
    if (updated == 0) await database.insert('professional_boards', row);
  }

  @override
  Future<void> delete(String id) => database.delete('professional_boards', where: 'id = ?', whereArgs: [id]);

  @override
  Future<List<String>> getCircuitIds(String boardId) async =>
    (await database.query('professional_board_circuits', columns:['circuit_id'],
      where:'board_id = ?', whereArgs:[boardId])).map((r)=>r['circuit_id']! as String).toList();

  @override
  Future<void> replaceCircuits(String boardId, Iterable<String> circuitIds) async {
    await database.transaction((txn) async {
      final boards = await txn.query('professional_boards', columns:['project_id'],
        where:'id = ?', whereArgs:[boardId], limit:1);
      if (boards.isEmpty) throw ArgumentError('Board not found.');
      final projectId = boards.single['project_id']! as String;
      final ids = circuitIds.toSet();
      for (final id in ids) {
        final circuits = await txn.query('professional_circuits', columns:['project_id'],
          where:'id = ?', whereArgs:[id], limit:1);
        if (circuits.isEmpty || circuits.single['project_id'] != projectId) {
          throw ArgumentError('Board and circuit must belong to the same project.');
        }
      }
      await txn.delete('professional_board_circuits', where:'board_id = ?', whereArgs:[boardId]);
      for (final id in ids) {
        await txn.insert('professional_board_circuits', {'board_id':boardId,'circuit_id':id});
      }
    });
  }

  ProfessionalBoard _fromRow(Map<String,Object?> r) => ProfessionalBoard(
    id:r['id']! as String, projectId:r['project_id']! as String, revision:r['revision']! as int,
    name:r['name']! as String, description:r['description'] as String? ?? '',
    location:r['location'] as String? ?? '', notes:r['notes'] as String? ?? '',
    status:r['status']=='closed'?ProfessionalBoardStatus.closed:ProfessionalBoardStatus.open,
    closedAt:r['closed_at']==null?null:DateTime.parse(r['closed_at']! as String),
    createdAt:DateTime.parse(r['created_at']! as String),
    updatedAt:DateTime.parse(r['updated_at']! as String)).normalized();
}
