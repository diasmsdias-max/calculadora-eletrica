import 'package:sqflite/sqflite.dart';

import 'professional_board.dart';
import 'professional_material.dart';

class ProfessionalBoardClosureService {
  final Database database;

  const ProfessionalBoardClosureService(this.database);

  Future<void> closeBoard({
    required ProfessionalBoard board,
    required Iterable<ProfessionalMaterial> generatedMaterials,
    required DateTime closedAt,
  }) async {
    final b = board.normalized();
    final source = 'VIS:${b.id}';
    final items = generatedMaterials.map((item) => item.normalized()).toList();

    if (items.any((item) => item.projectId != b.projectId || item.source != source)) {
      throw ArgumentError('Generated board materials must match board project and VIS source.');
    }

    await database.transaction((txn) async {
      await txn.delete(
        'professional_materials',
        where: 'project_id = ? AND source = ?',
        whereArgs: [b.projectId, source],
      );
      for (final item in items) {
        if (item.id.isEmpty || item.description.isEmpty || (item.quantity != null && item.quantity! <= 0)) {
          throw ArgumentError('Invalid generated material.');
        }
        await txn.insert('professional_materials', {
          'id': item.id,
          'project_id': item.projectId,
          'contract_version': ProfessionalMaterial.contractVersion,
          'revision': item.revision,
          'description': item.description,
          'category': item.category,
          'unit': item.unit,
          'quantity': item.quantity,
          'source': item.source,
          'notes': item.notes,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
        });
      }

      final updated = await txn.update(
        'professional_boards',
        {
          'contract_version': ProfessionalBoard.contractVersion,
          'revision': b.revision + 1,
          'name': b.name,
          'description': b.description,
          'location': b.location,
          'notes': b.notes,
          'status': ProfessionalBoardStatus.closed.name,
          'closed_at': closedAt.toUtc().toIso8601String(),
          'created_at': b.createdAt.toIso8601String(),
          'updated_at': closedAt.toUtc().toIso8601String(),
        },
        where: 'id = ? AND project_id = ?',
        whereArgs: [b.id, b.projectId],
      );
      if (updated != 1) {
        throw StateError('Board closure could not update the target board.');
      }
    });
  }
}
