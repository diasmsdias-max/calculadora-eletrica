import 'package:flutter/material.dart';
import '../../core/professional/professional_circuit.dart';
import '../../core/professional/professional_circuit_repository.dart';
import '../../core/professional/professional_circuit_aggregation.dart';
import '../../core/professional/professional_load.dart';
import '../../core/professional/professional_load_repository.dart';
import '../../core/professional/professional_sizing.dart';
import '../../core/professional/professional_sizing_repository.dart';
import '../../core/professional/professional_conductor_recommender.dart';
import '../../core/professional/professional_calculation_freshness.dart';
import '../../core/professional/professional_board_repository.dart';
import '../../core/professional/professional_closed_board_guard.dart';
import '../../core/calculations/quick_ampacity_reference.dart';

class ProfessionalSizingPage extends StatefulWidget {
  final ProfessionalSizingRepository repository;
  final ProfessionalCircuitRepository circuitsRepository;
  final ProfessionalLoadRepository loadsRepository;
  final ProfessionalBoardRepository boardsRepository;
  final String projectId; final bool readOnly;
  const ProfessionalSizingPage({super.key,required this.repository,required this.circuitsRepository,
    required this.loadsRepository,required this.boardsRepository,required this.projectId,required this.readOnly});
  @override State<ProfessionalSizingPage> createState()=>_State();
}
class _State extends State<ProfessionalSizingPage>{
  List<ProfessionalSizing> _items=const[];List<ProfessionalCircuit> _circuits=const[];
  List<ProfessionalLoad> _loads=const[];final Map<String,List<String>> _loadIdsByCircuit={};bool _loading=true;Set<String> _lockedCircuitIds=const{};
  @override void initState(){super.initState();_reload();}
  Future<void> _reload()async{final v=await Future.wait([widget.repository.getByProject(widget.projectId),
    widget.circuitsRepository.getByProject(widget.projectId),widget.loadsRepository.getByProject(widget.projectId),
    const ProfessionalClosedBoardGuard().lockedCircuitIds(boardsRepository:widget.boardsRepository,projectId:widget.projectId)]);
    final circuits=v[1] as List<ProfessionalCircuit>;final links=await Future.wait(circuits.map((c)=>widget.circuitsRepository.getLoadIds(c.id)));
    if(!mounted)return;setState((){_items=v[0] as List<ProfessionalSizing>;_circuits=circuits;_loads=v[2] as List<ProfessionalLoad>;
      _loadIdsByCircuit.clear();for(var i=0;i<circuits.length;i++){_loadIdsByCircuit[circuits[i].id]=links[i];}
      _lockedCircuitIds=v[3] as Set<String>;_loading=false;});}
  ProfessionalCircuitAggregation _aggregation(ProfessionalCircuit c){final ids=_loadIdsByCircuit[c.id]?.toSet()??<String>{};
    return const ProfessionalCircuitAggregator().calculate(circuit:c,loads:_loads.where((l)=>ids.contains(l.id)));}
  ProfessionalSizing? _for(String id){for(final x in _items){if(x.circuitId==id)return x;}return null;}
  bool _needsReview(ProfessionalCircuit c,ProfessionalSizing s){final ids=_loadIdsByCircuit[c.id]?.toSet()??<String>{};
    return ProfessionalCalculationFreshness.sizingNeedsReview(
      sizing:s,circuit:c,linkedLoads:_loads.where((l)=>ids.contains(l.id)));}
  Future<void> _edit(ProfessionalCircuit c)async{final ok=await showDialog<bool>(context:context,
    builder:(_)=>_SizingDialog(repository:widget.repository,projectId:widget.projectId,circuit:c,
      sizing:_for(c.id),aggregation:_aggregation(c),readOnly:widget.readOnly||_lockedCircuitIds.contains(c.id)));if(ok==true)await _reload();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Dimensionamento')),
    body:_loading?const Center(child:CircularProgressIndicator()):_circuits.isEmpty?
      const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Cadastre circuitos antes de registrar dimensionamentos.'))):
      ListView.separated(padding:const EdgeInsets.all(16),itemCount:_circuits.length,
        separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final c=_circuits[i],s=_for(c.id);
          final aggregation=_aggregation(c);
          final needsReview=s!=null&&_needsReview(c,s);
          final details=<String>[
            if(_lockedCircuitIds.contains(c.id))'Quadro fechado — reabra o quadro para alterar',
            if(needsReview)'Revisar cálculo',
            if(aggregation.designCurrentA!=null)'Ib ${aggregation.designCurrentA!.toStringAsFixed(2)} A',
            if(s?.conductorSectionMm2!=null)'${s!.conductorSectionMm2} mm²',
            if(s?.conductorAmpacityA!=null)'Iz ${s!.conductorAmpacityA} A',
            if(s?.voltageDropPercent!=null)'ΔV ${s!.voltageDropPercent}%'];
          return Card(child:ListTile(title:Text(c.name),
            subtitle:Text(s==null?'Dimensionamento ainda não registrado':
              details.isEmpty?'Registro técnico sem valores calculados':details.join(' • ')),
            leading:Icon(s==null?Icons.calculate_outlined:needsReview?Icons.warning_amber_outlined:Icons.check_circle_outline),
            trailing:const Icon(Icons.chevron_right),onTap:()=>_edit(c)));}));
}
class _SizingDialog extends StatefulWidget{
  final ProfessionalSizingRepository repository;final String projectId;final ProfessionalCircuit circuit;
  final ProfessionalSizing? sizing;final ProfessionalCircuitAggregation aggregation;final bool readOnly;
  const _SizingDialog({required this.repository,required this.projectId,required this.circuit,
    required this.sizing,required this.aggregation,required this.readOnly});
  @override State<_SizingDialog> createState()=>_SizingDialogState();
}
class _SizingDialogState extends State<_SizingDialog>{
  late final TextEditingController _section,_ampacity,_drop,_method,_criteria,_notes;
  final _key=GlobalKey<FormState>();
  QuickAmpacityMaterial _material=QuickAmpacityMaterial.copper;
  late int _loadedConductors;
  double _temperatureFactor=1;
  double _groupingFactor=1;
  @override void initState(){super.initState();final s=widget.sizing;
    _section=TextEditingController(text:s?.conductorSectionMm2?.toString()??'');
    _ampacity=TextEditingController(text:s?.conductorAmpacityA?.toString()??'');
    _drop=TextEditingController(text:s?.voltageDropPercent?.toString()??'');
    _method=TextEditingController(text:s?.method??'');_criteria=TextEditingController(text:s?.criteria??'');
    _notes=TextEditingController(text:s?.notes??'');
    _loadedConductors=widget.circuit.phases==3?3:2;}
  double? _n(String v)=>double.tryParse(v.trim().replaceAll(',','.'));
  InputDecoration _d(String l,String h)=>InputDecoration(labelText:l,hintText:h,border:const OutlineInputBorder());
  String? _positive(String? v){if(v==null||v.trim().isEmpty)return null;final n=_n(v);return n==null||n<=0?'Informe um valor maior que zero.':null;}
  ProfessionalConductorRecommendation? _recommendation(){
    final ib=widget.aggregation.designCurrentA;if(ib==null||ib<=0)return null;
    return const ProfessionalConductorRecommender().recommendB1(
      designCurrentA:ib,material:_material,loadedConductors:_loadedConductors,
      temperatureFactor:_temperatureFactor,groupingFactor:_groupingFactor);
  }
  void _acceptRecommendation(){final r=_recommendation();if(r==null||!r.hasRecommendation)return;
    setState((){_section.text=r.sectionMm2.toString();_ampacity.text=r.correctedAmpacityA!.toStringAsFixed(2);
      _method.text=r.method;_criteria.text='Material: ${_material==QuickAmpacityMaterial.copper?'cobre':'alumínio'}; '
        '$_loadedConductors condutores carregados; fator temperatura $_temperatureFactor; '
        'fator agrupamento $_groupingFactor; Iz corrigida ${r.correctedAmpacityA!.toStringAsFixed(2)} A.';});
  }
  Future<void> _save()async{if(!_key.currentState!.validate())return;final now=DateTime.now().toUtc(),old=widget.sizing;
    await widget.repository.save(ProfessionalSizing(id:old?.id??'sizing-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId:widget.projectId,circuitId:widget.circuit.id,revision:old==null?1:old.revision+1,
      designCurrentA:widget.aggregation.designCurrentA,
      conductorSectionMm2:_section.text.trim().isEmpty?null:_n(_section.text),
      conductorAmpacityA:_ampacity.text.trim().isEmpty?null:_n(_ampacity.text),
      voltageDropPercent:_drop.text.trim().isEmpty?null:_n(_drop.text),
      protectionCurrentA:old?.protectionCurrentA,
      method:_method.text,criteria:_criteria.text,notes:_notes.text,
      createdAt:old?.createdAt??now,updatedAt:now));if(mounted)Navigator.pop(context,true);}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text('Dimensionamento — ${widget.circuit.name}'),
    content:SizedBox(width:600,child:Form(key:_key,child:SingleChildScrollView(child:Column(children:[
      _AutomaticCurrentSummary(aggregation:widget.aggregation),
      const SizedBox(height:12),
      if(!widget.readOnly)_B1RecommendationControls(
        material:_material,loadedConductors:_loadedConductors,
        temperatureFactor:_temperatureFactor,groupingFactor:_groupingFactor,
        recommendation:_recommendation(),
        onMaterial:(v)=>setState(()=>_material=v),
        onLoadedConductors:(v)=>setState(()=>_loadedConductors=v),
        onTemperatureFactor:(v)=>setState(()=>_temperatureFactor=v),
        onGroupingFactor:(v)=>setState(()=>_groupingFactor=v),
        onAccept:_acceptRecommendation),
      if(!widget.readOnly)const SizedBox(height:12),
      TextFormField(controller:_section,readOnly:widget.readOnly,
        keyboardType:const TextInputType.numberWithOptions(decimal:true),
        decoration:_d('Seção do condutor (mm²)','Informe a seção adotada'),validator:_positive),
      const SizedBox(height:12),TextFormField(controller:_ampacity,readOnly:widget.readOnly,
        keyboardType:const TextInputType.numberWithOptions(decimal:true),
        decoration:_d('Capacidade de condução Iz (A)','Informe a capacidade válida para as condições adotadas'),validator:_positive),
      const SizedBox(height:12),TextFormField(controller:_drop,readOnly:widget.readOnly,
        keyboardType:const TextInputType.numberWithOptions(decimal:true),
        decoration:_d('Queda de tensão (%)','Informe o resultado quando calculado'),
        validator:(v){if(v==null||v.trim().isEmpty)return null;final n=_n(v);return n==null||n<0||n>100?'Informe um percentual entre 0 e 100.':null;}),
      const SizedBox(height:12),const _ProtectionSourceNotice(),
      const SizedBox(height:12),TextFormField(controller:_method,readOnly:widget.readOnly,
        decoration:_d('Método','Descreva o método de dimensionamento utilizado')),
      const SizedBox(height:12),TextFormField(controller:_criteria,readOnly:widget.readOnly,maxLines:3,
        decoration:_d('Critérios adotados','Registre critérios, hipóteses e condições consideradas')),
      const SizedBox(height:12),TextFormField(controller:_notes,readOnly:widget.readOnly,maxLines:3,
        decoration:_d('Observações','Informações complementares do dimensionamento'))
    ])))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(widget.readOnly?'Fechar':'Cancelar')),
      if(!widget.readOnly)FilledButton(onPressed:_save,child:const Text('Salvar'))]);
}




class _B1RecommendationControls extends StatelessWidget{
  final QuickAmpacityMaterial material;final int loadedConductors;
  final double temperatureFactor,groupingFactor;
  final ProfessionalConductorRecommendation? recommendation;
  final ValueChanged<QuickAmpacityMaterial> onMaterial;final ValueChanged<int> onLoadedConductors;
  final ValueChanged<double> onTemperatureFactor,onGroupingFactor;final VoidCallback onAccept;
  const _B1RecommendationControls({required this.material,required this.loadedConductors,
    required this.temperatureFactor,required this.groupingFactor,required this.recommendation,
    required this.onMaterial,required this.onLoadedConductors,required this.onTemperatureFactor,
    required this.onGroupingFactor,required this.onAccept});
  @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
    crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Sugestão VIS — referência B1',style:Theme.of(context).textTheme.titleSmall),
      const SizedBox(height:8),
      DropdownButtonFormField<QuickAmpacityMaterial>(initialValue:material,
        decoration:const InputDecoration(labelText:'Material',border:OutlineInputBorder()),
        items:const [DropdownMenuItem(value:QuickAmpacityMaterial.copper,child:Text('Cobre')),
          DropdownMenuItem(value:QuickAmpacityMaterial.aluminum,child:Text('Alumínio'))],
        onChanged:(v){if(v!=null)onMaterial(v);}),
      const SizedBox(height:8),
      DropdownButtonFormField<int>(initialValue:loadedConductors,
        decoration:const InputDecoration(labelText:'Condutores carregados',border:OutlineInputBorder()),
        items:const [DropdownMenuItem(value:2,child:Text('2')),DropdownMenuItem(value:3,child:Text('3'))],
        onChanged:(v){if(v!=null)onLoadedConductors(v);}),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child:DropdownButtonFormField<double>(initialValue:temperatureFactor,
          decoration:const InputDecoration(labelText:'Fator temperatura',border:OutlineInputBorder()),
          items:const [1.0,0.94,0.87,0.79,0.71].map((v)=>DropdownMenuItem(value:v,child:Text(v.toString()))).toList(),
          onChanged:(v){if(v!=null)onTemperatureFactor(v);})),
        const SizedBox(width:8),
        Expanded(child:DropdownButtonFormField<double>(initialValue:groupingFactor,
          decoration:const InputDecoration(labelText:'Fator agrupamento',border:OutlineInputBorder()),
          items:const [1.0,0.8,0.7,0.65,0.6,0.57].map((v)=>DropdownMenuItem(value:v,child:Text(v.toString()))).toList(),
          onChanged:(v){if(v!=null)onGroupingFactor(v);})),
      ]),
      const SizedBox(height:8),
      Text(recommendation==null?'Ib ainda não disponível para recomendar condutor.':
        recommendation!.hasRecommendation
          ?'Sugestão: ${recommendation!.sectionMm2} mm² • Iz corrigida ${recommendation!.correctedAmpacityA!.toStringAsFixed(2)} A'
          :recommendation!.message),
      if(recommendation?.hasRecommendation==true)...[const SizedBox(height:8),
        FilledButton.tonal(onPressed:onAccept,child:const Text('Aceitar recomendação'))],
      const SizedBox(height:6),
      const Text('Referência rápida PVC 70 °C — método B1. Para outro método ou condição, altere os valores e registre o critério adotado.'),
    ])));
}

class _AutomaticCurrentSummary extends StatelessWidget{
  final ProfessionalCircuitAggregation aggregation;const _AutomaticCurrentSummary({required this.aggregation});
  @override Widget build(BuildContext context){final ib=aggregation.designCurrentA;return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Corrente de projeto (Ib)',style:Theme.of(context).textTheme.titleSmall),const SizedBox(height:6),
    Text(ib==null?'Não calculada':'${ib.toStringAsFixed(2)} A — calculada automaticamente'),
    const SizedBox(height:4),const Text('Origem: cargas vinculadas ao circuito. O Ib considera o FS adotado em cada carga e não é digitado manualmente.'),
    const SizedBox(height:4),Text(aggregation.currentMessage),
    if(aggregation.linkedLoadCount>0)Text('${aggregation.linkedLoadCount} carga(s) vinculada(s) • ${aggregation.totalPowerW.toStringAsFixed(0)} W instalados'),
  ])));}
}


class _ProtectionSourceNotice extends StatelessWidget{
  const _ProtectionSourceNotice();
  @override Widget build(BuildContext context)=>const Card(child:Padding(padding:EdgeInsets.all(12),child:Text(
    'Proteção (In): definida no módulo Proteções. '
    'Aqui ficam os dados de dimensionamento do circuito: Ib, seção do condutor, Iz e queda de tensão. '
    'O VIS ELECTRICA cruza esses dados automaticamente na validação Ib ≤ In ≤ Iz.'
  )));
}
