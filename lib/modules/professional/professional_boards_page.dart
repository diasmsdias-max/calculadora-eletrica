import 'package:flutter/material.dart';
import '../../core/professional/professional_board.dart';
import '../../core/professional/professional_board_repository.dart';
import '../../core/professional/professional_circuit.dart';
import '../../core/professional/professional_circuit_repository.dart';

class ProfessionalBoardsPage extends StatefulWidget {
  final ProfessionalBoardRepository repository;
  final ProfessionalCircuitRepository circuitsRepository;
  final String projectId;
  final bool readOnly;
  const ProfessionalBoardsPage({super.key, required this.repository, required this.circuitsRepository,
    required this.projectId, required this.readOnly});
  @override State<ProfessionalBoardsPage> createState()=>_ProfessionalBoardsPageState();
}

class _ProfessionalBoardsPageState extends State<ProfessionalBoardsPage> {
  List<ProfessionalBoard> _boards=const[]; List<ProfessionalCircuit> _circuits=const[];
  final _search=TextEditingController(); String _query=''; bool _loading=true;
  @override void initState(){super.initState();_reload();}
  @override void dispose(){_search.dispose();super.dispose();}
  Future<void> _reload() async {
    final v=await Future.wait([widget.repository.getByProject(widget.projectId),
      widget.circuitsRepository.getByProject(widget.projectId)]);
    if(!mounted)return; setState((){_boards=v[0] as List<ProfessionalBoard>;
      _circuits=v[1] as List<ProfessionalCircuit>;_loading=false;});
  }
  Future<void> _edit([ProfessionalBoard? board]) async {
    if(widget.readOnly&&board==null)return;
    final selected=board==null?<String>[]:await widget.repository.getCircuitIds(board.id);
    if(!mounted)return;
    final saved=await showDialog<bool>(context:context,builder:(_)=>_BoardDialog(
      repository:widget.repository,projectId:widget.projectId,board:board,
      circuits:_circuits,selectedCircuitIds:selected,readOnly:widget.readOnly));
    if(saved==true)await _reload();
  }
  @override Widget build(BuildContext context){
    final q=_query.trim().toLowerCase();
    final items=q.isEmpty?_boards:_boards.where((b)=>b.name.toLowerCase().contains(q)||
      b.description.toLowerCase().contains(q)||b.location.toLowerCase().contains(q)||
      b.notes.toLowerCase().contains(q)).toList();
    return Scaffold(appBar:AppBar(title:const Text('Quadros')),
      floatingActionButton:widget.readOnly?null:FloatingActionButton.extended(
        onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('Novo quadro')),
      body:_loading?const Center(child:CircularProgressIndicator()):Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:TextField(
          controller:_search,onChanged:(v)=>setState(()=>_query=v),
          decoration:InputDecoration(labelText:'Buscar quadros',
            hintText:'Nome, localização, descrição ou observação',prefixIcon:const Icon(Icons.search),
            suffixIcon:q.isEmpty?null:IconButton(icon:const Icon(Icons.clear),onPressed:(){
              _search.clear();setState(()=>_query='');}),border:const OutlineInputBorder()))),
        Expanded(child:_boards.isEmpty?const Center(child:Text('Nenhum quadro cadastrado neste projeto.')):
          items.isEmpty?const Center(child:Text('Nenhum quadro encontrado para esta busca.')):
          ListView.separated(padding:const EdgeInsets.fromLTRB(16,8,16,96),itemCount:items.length,
            separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){
              final b=items[i]; return Card(child:ListTile(title:Text(b.name),
                subtitle:b.location.isEmpty?null:Text(b.location),trailing:const Icon(Icons.chevron_right),
                onTap:()=>_edit(b)));}))
      ]));
  }
}

class _BoardDialog extends StatefulWidget {
  final ProfessionalBoardRepository repository; final String projectId; final ProfessionalBoard? board;
  final List<ProfessionalCircuit> circuits; final List<String> selectedCircuitIds; final bool readOnly;
  const _BoardDialog({required this.repository,required this.projectId,required this.board,
    required this.circuits,required this.selectedCircuitIds,required this.readOnly});
  @override State<_BoardDialog> createState()=>_BoardDialogState();
}
class _BoardDialogState extends State<_BoardDialog>{
  final _key=GlobalKey<FormState>(); late final TextEditingController _name,_description,_location,_notes;
  late final Set<String> _selected;
  @override void initState(){super.initState();final b=widget.board;
    _name=TextEditingController(text:b?.name??'');_description=TextEditingController(text:b?.description??'');
    _location=TextEditingController(text:b?.location??'');_notes=TextEditingController(text:b?.notes??'');
    _selected=widget.selectedCircuitIds.toSet();}
  InputDecoration _d(String l,String h)=>InputDecoration(labelText:l,hintText:h,border:const OutlineInputBorder());
  Future<void> _save()async{if(!_key.currentState!.validate())return;final now=DateTime.now().toUtc();final old=widget.board;
    final b=ProfessionalBoard(id:old?.id??'board-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId:widget.projectId,revision:old==null?1:old.revision+1,name:_name.text,
      description:_description.text,location:_location.text,notes:_notes.text,
      createdAt:old?.createdAt??now,updatedAt:now);
    await widget.repository.save(b);await widget.repository.replaceCircuits(b.id,_selected);
    if(mounted)Navigator.of(context).pop(true);}
  @override Widget build(BuildContext context)=>AlertDialog(
    title:Text(widget.board==null?'Novo quadro':widget.board!.name),
    content:SizedBox(width:560,child:Form(key:_key,child:SingleChildScrollView(child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        TextFormField(controller:_name,readOnly:widget.readOnly,decoration:_d('Nome do quadro','Identifique o quadro no projeto'),
          validator:(v)=>v==null||v.trim().isEmpty?'Informe o nome do quadro.':null),
        const SizedBox(height:12),TextFormField(controller:_description,readOnly:widget.readOnly,
          decoration:_d('Descrição','Descreva a finalidade do quadro')),
        const SizedBox(height:12),TextFormField(controller:_location,readOnly:widget.readOnly,
          decoration:_d('Localização','Informe onde o quadro está ou será instalado')),
        const SizedBox(height:16),Text('Circuitos do quadro',style:Theme.of(context).textTheme.titleMedium),
        if(widget.circuits.isEmpty)const Padding(padding:EdgeInsets.only(top:8),
          child:Text('Cadastre circuitos no projeto para vinculá-los ao quadro.'))
        else ...widget.circuits.map((c)=>CheckboxListTile(value:_selected.contains(c.id),
          onChanged:widget.readOnly?null:(v)=>setState((){if(v==true){_selected.add(c.id);}else{_selected.remove(c.id);}}),
          title:Text(c.name),subtitle:c.description.isEmpty?null:Text(c.description),
          controlAffinity:ListTileControlAffinity.leading,contentPadding:EdgeInsets.zero)),
        const SizedBox(height:12),TextFormField(controller:_notes,readOnly:widget.readOnly,maxLines:3,
          decoration:_d('Observações','Informações complementares do quadro'))
      ])))),
    actions:[TextButton(onPressed:()=>Navigator.of(context).pop(false),child:Text(widget.readOnly?'Fechar':'Cancelar')),
      if(!widget.readOnly)FilledButton(onPressed:_save,child:const Text('Salvar'))]);
}
