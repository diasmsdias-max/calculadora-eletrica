import 'professional_board.dart';
import 'professional_circuit.dart';
import 'professional_load.dart';
import 'professional_protection.dart';
import 'professional_sizing.dart';

class ProfessionalMemorialSnapshot {
  final String scope, criteria;
  const ProfessionalMemorialSnapshot({required this.scope, required this.criteria});
}

class ProfessionalMemorialConsolidator {
  const ProfessionalMemorialConsolidator();
  ProfessionalMemorialSnapshot build({
    required Iterable<ProfessionalBoard> boards,
    required Iterable<ProfessionalCircuit> circuits,
    required Iterable<ProfessionalLoad> loads,
    required Iterable<ProfessionalSizing> sizing,
    required Iterable<ProfessionalProtection> protections,
  }) {
    final bs=boards.toList(), cs=circuits.toList(), ls=loads.toList(), ss=sizing.toList(), ps=protections.toList();
    final closed=bs.where((b)=>b.isClosed).length;
    final scope='Projeto elétrico consolidado no VIS ELECTRICA: ${ls.length} carga(s), ${cs.length} circuito(s) e ${bs.length} quadro(s), sendo $closed fechado(s).';
    final lines=<String>[
      'Dimensionamentos registrados: ${ss.length}/${cs.length} circuito(s).',
      'Proteções registradas: ${ps.length}.',
      'Os resultados utilizam exclusivamente os dados cadastrados no projeto; campos não informados permanecem indefinidos.',
    ];
    for(final c in cs){
      ProfessionalSizing? sz; for(final x in ss){if(x.circuitId==c.id){sz=x;break;}}
      final cp=ps.where((p)=>p.circuitId==c.id).length;
      lines.add('${c.name}: ${sz==null?'sem dimensionamento':'dimensionado'}; $cp proteção(ões).');
    }
    return ProfessionalMemorialSnapshot(scope:scope,criteria:lines.join('\n'));
  }
}