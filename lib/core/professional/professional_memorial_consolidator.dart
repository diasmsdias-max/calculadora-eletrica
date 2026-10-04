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
    final subject=bs.length==1?'Quadro ${bs.single.name} consolidado':'Projeto elétrico consolidado';
    final scope='$subject no VIS ELECTRICA: ${ls.length} carga(s), ${cs.length} circuito(s) e ${bs.length} quadro(s), sendo $closed fechado(s).';
    final lines=<String>[
      'Dimensionamentos registrados: ${ss.length}/${cs.length} circuito(s).',
      'Proteções registradas: ${ps.length}.',
      'Os resultados utilizam exclusivamente os dados cadastrados no projeto; campos não informados permanecem indefinidos.',
    ];
    for(final c in cs){
      ProfessionalSizing? sz; for(final x in ss){if(x.circuitId==c.id){sz=x;break;}}
      final circuitProtections=ps.where((p)=>p.circuitId==c.id).toList();
      final cp=circuitProtections.length;
      ProfessionalProtection? overcurrent;
      for(final p in circuitProtections){
        if(p.role==ProfessionalProtectionRole.overcurrent&&p.ratedCurrentA!=null){
          overcurrent=p;break;
        }
      }
      final details=<String>[
        sz==null?'sem dimensionamento':'dimensionado',
        '$cp proteção(ões)',
        if(sz?.designCurrentA!=null)'Ib=${_n(sz!.designCurrentA!)} A',
        if(overcurrent?.ratedCurrentA!=null)'In=${_n(overcurrent!.ratedCurrentA!)} A',
        if(sz?.conductorAmpacityA!=null)'Iz=${_n(sz!.conductorAmpacityA!)} A',
        if(sz?.conductorSectionMm2!=null)'condutor=${_n(sz!.conductorSectionMm2!)} mm²',
      ];
      lines.add('${c.name}: ${details.join('; ')}.');
    }
    return ProfessionalMemorialSnapshot(scope:scope,criteria:lines.join('\n'));
  }

  static String _n(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('0') ? fixed.substring(0, fixed.length - 1) : fixed;
  }
}