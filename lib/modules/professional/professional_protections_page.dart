import 'package:flutter/material.dart';
import '../../core/professional/professional_circuit.dart';
import '../../core/professional/professional_circuit_repository.dart';
import '../../core/professional/professional_circuit_aggregation.dart';
import '../../core/professional/professional_load.dart';
import '../../core/professional/professional_load_repository.dart';
import '../../core/professional/professional_protection.dart';
import '../../core/professional/professional_protection_repository.dart';
import '../../core/professional/professional_sizing.dart';
import '../../core/professional/professional_sizing_repository.dart';
import '../../core/professional/overcurrent_protection_validator.dart';
import '../../core/professional/technical_validation.dart';

class ProfessionalProtectionsPage extends StatefulWidget {
  final ProfessionalProtectionRepository repository;
  final ProfessionalCircuitRepository circuitsRepository;
  final ProfessionalSizingRepository sizingRepository;
  final ProfessionalLoadRepository loadsRepository;
  final String projectId; final bool readOnly;
  const ProfessionalProtectionsPage({super.key,required this.repository,required this.circuitsRepository,
    required this.sizingRepository,required this.loadsRepository,required this.projectId,required this.readOnly});
  @override State<ProfessionalProtectionsPage> createState()=>_State();
}
class _State extends State<ProfessionalProtectionsPage>{
  List<ProfessionalProtection> _items=const[]; List<ProfessionalCircuit> _circuits=const[]; List<ProfessionalSizing> _sizing=const[];
  List<ProfessionalLoad> _loads=const[];final Map<String,List<String>> _loadIdsByCircuit={};
  final _search=TextEditingController();String _query='';bool _loading=true;
  @override void initState(){super.initState();_reload();}
  @override void dispose(){_search.dispose();super.dispose();}
  Future<void> _reload()async{final v=await Future.wait([widget.repository.getByProject(widget.projectId),
    widget.circuitsRepository.getByProject(widget.projectId),widget.sizingRepository.getByProject(widget.projectId),widget.loadsRepository.getByProject(widget.projectId)]);
    final circuits=v[1] as List<ProfessionalCircuit>;final links=await Future.wait(circuits.map((c)=>widget.circuitsRepository.getLoadIds(c.id)));
    if(!mounted)return;setState((){_items=v[0] as List<ProfessionalProtection>;_circuits=circuits;_sizing=v[2] as List<ProfessionalSizing>;_loads=v[3] as List<ProfessionalLoad>;
      _loadIdsByCircuit.clear();for(var i=0;i<circuits.length;i++){_loadIdsByCircuit[circuits[i].id]=links[i];}_loading=false;});}
  Future<void> _edit([ProfessionalProtection? p])async{
    if(widget.readOnly&&p==null)return;
    final ok=await showDialog<bool>(context:context,builder:(_)=>_ProtectionDialog(repository:widget.repository,
      projectId:widget.projectId,protection:p,circuits:_circuits,sizing:_sizing,loads:_loads,
      loadIdsByCircuit:_loadIdsByCircuit,readOnly:widget.readOnly));
    if(ok==true)await _reload();
  }
  @override Widget build(BuildContext context){final q=_query.trim().toLowerCase();
    final list=q.isEmpty?_items:_items.where((p)=>p.name.toLowerCase().contains(q)||
      p.deviceType.toLowerCase().contains(q)||p.tripCurve.toLowerCase().contains(q)||
      p.notes.toLowerCase().contains(q)).toList();
    return Scaffold(appBar:AppBar(title:const Text('Proteções')),
      floatingActionButton:widget.readOnly?null:FloatingActionButton.extended(onPressed:_circuits.isEmpty?null:()=>_edit(),
        icon:const Icon(Icons.add),label:const Text('Nova proteção')),
      body:_loading?const Center(child:CircularProgressIndicator()):Column(children:[
        if(_circuits.isEmpty)const Padding(padding:EdgeInsets.all(16),
          child:Text('Cadastre ao menos um circuito antes de adicionar proteções.')),
        Padding(padding:const EdgeInsets.fromLTRB(16,8,16,8),child:TextField(controller:_search,
          onChanged:(v)=>setState(()=>_query=v),decoration:InputDecoration(labelText:'Buscar proteções',
          hintText:'Nome, tipo, curva ou observação',prefixIcon:const Icon(Icons.search),
          suffixIcon:q.isEmpty?null:IconButton(icon:const Icon(Icons.clear),onPressed:(){_search.clear();setState(()=>_query='');}),
          border:const OutlineInputBorder()))),
        Expanded(child:_items.isEmpty?const Center(child:Text('Nenhuma proteção cadastrada neste projeto.')):
          list.isEmpty?const Center(child:Text('Nenhuma proteção encontrada para esta busca.')):
          ListView.separated(padding:const EdgeInsets.fromLTRB(16,8,16,96),itemCount:list.length,
            separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final p=list[i];
              final circuit=_circuits.where((c)=>c.id==p.circuitId).firstOrNull;
              return Card(child:ListTile(title:Text(p.name),subtitle:Text([
                if(p.deviceType.isNotEmpty)p.deviceType,if(circuit!=null)circuit.name,
                if(p.recommendedCurrentA!=null)'Recomendado: ${p.recommendedCurrentA} A',
                if(p.ratedCurrentA!=null)'Adotado: ${p.ratedCurrentA} A',
                if(p.validationStatus.isNotEmpty)p.validationStatus].join(' • ')),
                trailing:const Icon(Icons.chevron_right),onTap:()=>_edit(p)));}))
      ]));
  }
}
class _ProtectionDialog extends StatefulWidget{
  final ProfessionalProtectionRepository repository;final String projectId;
  final ProfessionalProtection? protection;final List<ProfessionalCircuit> circuits;final List<ProfessionalSizing> sizing;
  final List<ProfessionalLoad> loads;final Map<String,List<String>> loadIdsByCircuit;final bool readOnly;
  const _ProtectionDialog({required this.repository,required this.projectId,required this.protection,
    required this.circuits,required this.sizing,required this.loads,required this.loadIdsByCircuit,required this.readOnly});
  @override State<_ProtectionDialog> createState()=>_ProtectionDialogState();
}
class _ProtectionDialogState extends State<_ProtectionDialog>{
  final _key=GlobalKey<FormState>();late String? _circuitId;
  late final TextEditingController _name,_type,_current,_poles,_curve,_breaking,_notes;
  @override void initState(){super.initState();final p=widget.protection;_circuitId=p?.circuitId;
    _name=TextEditingController(text:p?.name??'');_type=TextEditingController(text:p?.deviceType??'');
    _current=TextEditingController(text:p?.ratedCurrentA?.toString()??'');_poles=TextEditingController(text:p?.poles?.toString()??'');
    _curve=TextEditingController(text:p?.tripCurve??'');_breaking=TextEditingController(text:p?.breakingCapacityKa?.toString()??'');
    _notes=TextEditingController(text:p?.notes??'');}
  double? _n(String v)=>double.tryParse(v.trim().replaceAll(',','.'));
  ProfessionalSizing? _sizingFor(String? circuitId){if(circuitId==null)return null;for(final s in widget.sizing){if(s.circuitId==circuitId)return s;}return null;}
  double? _calculatedIb(){if(_circuitId==null)return null;ProfessionalCircuit? circuit;for(final c in widget.circuits){if(c.id==_circuitId)circuit=c;}if(circuit==null)return null;
    final ids=widget.loadIdsByCircuit[_circuitId]?.toSet()??<String>{};return const ProfessionalCircuitAggregator().calculate(circuit:circuit,loads:widget.loads.where((l)=>ids.contains(l.id))).designCurrentA;}
  TechnicalValidationResult _validation(){final s=_sizingFor(_circuitId);return OvercurrentProtectionValidator.validate(designCurrentA:_calculatedIb(),adoptedProtectionCurrentA:_current.text.trim().isEmpty?null:_n(_current.text),conductorAmpacityA:s?.conductorAmpacityA);}
  InputDecoration _d(String l,String h)=>InputDecoration(labelText:l,hintText:h,border:const OutlineInputBorder());
  Future<void> _save()async{if(!_key.currentState!.validate())return;final now=DateTime.now().toUtc();final old=widget.protection;
    await widget.repository.save(ProfessionalProtection(id:old?.id??'protection-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId:widget.projectId,circuitId:_circuitId!,revision:old==null?1:old.revision+1,name:_name.text,
      deviceType:_type.text,ratedCurrentA:_current.text.trim().isEmpty?null:_n(_current.text),
      validationStatus:_validation().status.name,validationCriterion:_validation().criterion??'',
      poles:_poles.text.trim().isEmpty?null:int.tryParse(_poles.text.trim()),tripCurve:_curve.text,
      breakingCapacityKa:_breaking.text.trim().isEmpty?null:_n(_breaking.text),notes:_notes.text,
      createdAt:old?.createdAt??now,updatedAt:now));if(mounted)Navigator.of(context).pop(true);}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.protection==null?'Nova proteção':widget.protection!.name),
    content:SizedBox(width:560,child:Form(key:_key,child:SingleChildScrollView(child:Column(children:[
      DropdownButtonFormField<String>(initialValue:_circuitId,decoration:_d('Circuito','Selecione o circuito protegido'),
        items:widget.circuits.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.name))).toList(),
        onChanged:widget.readOnly?null:(v)=>setState(()=>_circuitId=v),
        validator:(v)=>v==null?'Selecione um circuito.':null),
      const SizedBox(height:12),TextFormField(controller:_name,readOnly:widget.readOnly,
        decoration:_d('Nome da proteção','Identifique o dispositivo ou função de proteção'),
        validator:(v)=>v==null||v.trim().isEmpty?'Informe o nome da proteção.':null),
      const SizedBox(height:12),TextFormField(controller:_type,readOnly:widget.readOnly,
        decoration:_d('Tipo de dispositivo','Ex.: disjuntor, DR ou DPS')),
      const SizedBox(height:12),
      if(widget.protection?.recommendedCurrentA!=null)
        _ValidationSummary(protection:widget.protection!),
      if(widget.protection?.recommendedCurrentA!=null)const SizedBox(height:12),
      _LiveProtectionValidation(result:_validation(),sizing:_sizingFor(_circuitId),calculatedIb:_calculatedIb()),
      const SizedBox(height:12),TextFormField(controller:_current,readOnly:widget.readOnly,
        onChanged:(_)=>setState((){}),
        keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:_d('Corrente adotada (A)','Informe o valor adotado pelo profissional'),
        validator:(v){if(v==null||v.trim().isEmpty)return null;final n=_n(v);return n==null||n<=0?'Informe uma corrente válida.':null;}),
      const SizedBox(height:12),TextFormField(controller:_poles,readOnly:widget.readOnly,keyboardType:TextInputType.number,
        decoration:_d('Número de polos','Informe de 1 a 4 quando definido'),
        validator:(v){if(v==null||v.trim().isEmpty)return null;final n=int.tryParse(v);return n==null||n<1||n>4?'Informe de 1 a 4 polos.':null;}),
      const SizedBox(height:12),TextFormField(controller:_curve,readOnly:widget.readOnly,
        decoration:_d('Curva / característica','Informe quando aplicável ao dispositivo')),
      const SizedBox(height:12),TextFormField(controller:_breaking,readOnly:widget.readOnly,
        keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:_d('Capacidade de interrupção (kA)','Informe quando conhecida'),
        validator:(v){if(v==null||v.trim().isEmpty)return null;final n=_n(v);return n==null||n<=0?'Informe uma capacidade válida.':null;}),
      const SizedBox(height:12),TextFormField(controller:_notes,readOnly:widget.readOnly,maxLines:3,
        decoration:_d('Observações','Informações complementares da proteção'))
    ])))),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(widget.readOnly?'Fechar':'Cancelar')),
      if(!widget.readOnly)FilledButton(onPressed:_save,child:const Text('Salvar'))]);
}


class _ValidationSummary extends StatelessWidget {
  final ProfessionalProtection protection;
  const _ValidationSummary({required this.protection});

  @override
  Widget build(BuildContext context) {
    final recommended=protection.recommendedCurrentA;
    if(recommended==null)return const SizedBox.shrink();
    final status=protection.validationStatus.trim().isEmpty
        ? 'Aguardando validação'
        : protection.validationStatus;
    return Card(
      child:Padding(
        padding:const EdgeInsets.all(12),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text('Recomendação do VIS ELECTRICA',
              style:Theme.of(context).textTheme.titleSmall),
            const SizedBox(height:6),
            Text('Corrente recomendada: $recommended A'),
            Text('Situação: $status'),
            if(protection.validationCriterion.trim().isNotEmpty)
              Text('Critério: ${protection.validationCriterion}'),
            const SizedBox(height:6),
            const Text(
              'O valor recomendado orienta a decisão técnica. '
              'O profissional pode adotar outro valor; divergências devem ser validadas.',
            ),
          ],
        ),
      ),
    );
  }
}


class _LiveProtectionValidation extends StatelessWidget{
  final TechnicalValidationResult result;final ProfessionalSizing? sizing;final double? calculatedIb;
  const _LiveProtectionValidation({required this.result,required this.sizing,required this.calculatedIb});
  @override Widget build(BuildContext context){final ib=calculatedIb,iz=sizing?.conductorAmpacityA;return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Validação da proteção',style:Theme.of(context).textTheme.titleSmall),const SizedBox(height:6),
    const Text('Critério: Ib ≤ In ≤ Iz'),Text('Ib: ${ib?.toStringAsFixed(2)??'não calculada'} A • Iz: ${iz?.toStringAsFixed(2)??'não informada'} A'),
    const SizedBox(height:4),Text(result.title),Text(result.message),
    const SizedBox(height:6),const Text('A validação orienta a decisão técnica e não bloqueia a escolha do profissional.'),
  ])));}
}
