import 'package:flutter/material.dart';
import '../../core/professional/professional_circuit.dart';
import '../../core/professional/professional_circuit_repository.dart';
import '../../core/professional/professional_protection.dart';
import '../../core/professional/professional_protection_repository.dart';

class ProfessionalProtectionsPage extends StatefulWidget {
  final ProfessionalProtectionRepository repository;
  final ProfessionalCircuitRepository circuitsRepository;
  final String projectId; final bool readOnly;
  const ProfessionalProtectionsPage({super.key,required this.repository,required this.circuitsRepository,
    required this.projectId,required this.readOnly});
  @override State<ProfessionalProtectionsPage> createState()=>_State();
}
class _State extends State<ProfessionalProtectionsPage>{
  List<ProfessionalProtection> _items=const[]; List<ProfessionalCircuit> _circuits=const[];
  final _search=TextEditingController();String _query='';bool _loading=true;
  @override void initState(){super.initState();_reload();}
  @override void dispose(){_search.dispose();super.dispose();}
  Future<void> _reload()async{final v=await Future.wait([widget.repository.getByProject(widget.projectId),
    widget.circuitsRepository.getByProject(widget.projectId)]);if(!mounted)return;
    setState((){_items=v[0] as List<ProfessionalProtection>;_circuits=v[1] as List<ProfessionalCircuit>;_loading=false;});}
  Future<void> _edit([ProfessionalProtection? p])async{
    if(widget.readOnly&&p==null)return;
    final ok=await showDialog<bool>(context:context,builder:(_)=>_ProtectionDialog(repository:widget.repository,
      projectId:widget.projectId,protection:p,circuits:_circuits,readOnly:widget.readOnly));
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
                if(p.ratedCurrentA!=null)'${p.ratedCurrentA} A'].join(' • ')),
                trailing:const Icon(Icons.chevron_right),onTap:()=>_edit(p)));}))
      ]));
  }
}
class _ProtectionDialog extends StatefulWidget{
  final ProfessionalProtectionRepository repository;final String projectId;
  final ProfessionalProtection? protection;final List<ProfessionalCircuit> circuits;final bool readOnly;
  const _ProtectionDialog({required this.repository,required this.projectId,required this.protection,
    required this.circuits,required this.readOnly});
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
  InputDecoration _d(String l,String h)=>InputDecoration(labelText:l,hintText:h,border:const OutlineInputBorder());
  Future<void> _save()async{if(!_key.currentState!.validate())return;final now=DateTime.now().toUtc();final old=widget.protection;
    await widget.repository.save(ProfessionalProtection(id:old?.id??'protection-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId:widget.projectId,circuitId:_circuitId!,revision:old==null?1:old.revision+1,name:_name.text,
      deviceType:_type.text,ratedCurrentA:_current.text.trim().isEmpty?null:_n(_current.text),
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
      const SizedBox(height:12),TextFormField(controller:_current,readOnly:widget.readOnly,
        keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:_d('Corrente nominal (A)','Informe quando definida'),
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
