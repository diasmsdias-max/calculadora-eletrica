import 'professional_material.dart';
import 'professional_protection.dart';

class ProfessionalBoardMaterialConsolidator {
  const ProfessionalBoardMaterialConsolidator();

  List<ProfessionalMaterial> build({
    required String projectId, required String boardId,
    required Iterable<String> circuitIds,
    required Iterable<ProfessionalProtection> protections,
    required DateTime generatedAt,
  }) {
    final ids = circuitIds.toSet();
    final relevant = protections.where((p) => ids.contains(p.circuitId));
    final grouped = <String, List<ProfessionalProtection>>{};
    for (final p in relevant) {
      final key = [p.role?.name ?? 'other', p.deviceType, p.ratedCurrentA?.toString() ?? '',
        p.poles?.toString() ?? '', p.tripCurve].join('|');
      (grouped[key] ??= <ProfessionalProtection>[]).add(p);
    }
    final keys = grouped.keys.toList()..sort();
    var index = 0;
    return keys.map((key) {
      final group = grouped[key]!;
      final p = group.first; index++;
      final details = <String>[
        if (p.deviceType.isNotEmpty) p.deviceType,
        if (p.ratedCurrentA != null) '${_n(p.ratedCurrentA!)} A',
        if (p.poles != null) '${p.poles}P',
        if (p.tripCurve.isNotEmpty) 'curva ${p.tripCurve}',
      ];
      return ProfessionalMaterial(
        id: 'vis-$boardId-protection-$index', projectId: projectId, revision: 1,
        description: p.name.isNotEmpty ? p.name : (details.isEmpty ? 'Proteção elétrica' : details.join(' ')),
        category: 'Proteções', unit: 'un', quantity: group.length.toDouble(), source: 'VIS:$boardId',
        notes: details.join(' • '), createdAt: generatedAt, updatedAt: generatedAt);
    }).toList(growable: false);
  }

  String _n(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();
}