import 'package:flutter/material.dart';
import '../../core/professional/professional_material.dart';
import '../../core/professional/professional_material_repository.dart';

class ProfessionalMaterialsPage extends StatefulWidget{
 final ProfessionalMaterialRepository repository;final String projectId;final bool readOnly;
 const ProfessionalMaterialsPage({super.key,required this.repository,required this.projectId,required this.readOnly});
 @override State<ProfessionalMaterialsPage> createState()=>_State();
}
class _State extends State<ProfessionalMaterialsPage>{
 List<ProfessionalMaterial> _items=const[];final _search=TextEditingController();String _query='';bool _loading=true;
 @override void initState(){super.initState();_reload();} @override void dispose(){_search.dispose();super.dispose();}
 Future<void> _reload()async{final v=await widget.repository.getByProject(widget.projectId);if(mounted)setState((){_items=v;_loading=false;});}
 Future<void> _edit([ProfessionalMaterial? m])async{if(widget.readOnly&&m==null)return;
  final ok=await showDialog<bool>(context:context,builder:(_)=>_MaterialDialog(repository:widget.repository,
   projectId:widget.projectId,material:m,readOnly:widget.readOnly));if(ok==true)await _reload();}
 @override Widget build(BuildContext context){final q=_query.trim().toLowerCase();final list=q.isEmpty?_items:_items.where((m)=>
  m.description.toLowerCase().contains(q)||m.category.toLowerCase().contains(q)||m.unit.toLowerCase().contains(q)||
  m.source.toLowerCase().contains(q)||m.notes.toLowerCase().contains(q)).toList();
  return Scaffold(appBar:AppBar(title:const Text('Materiais')),
   floatingActionButton:widget.readOnly?null:FloatingActionButton.extended(onPressed:()=>_edit(),
    icon:const Icon(Icons.add),label:const Text('Novo material')),
   body:_loading?const Center(child:CircularProgressIndicator()):Column(children:[
    Padding(padding:const EdgeInsets.all(16),child:TextField(controller:_search,onChanged:(v)=>setState(()=>_query=v),
     decoration:InputDecoration(labelText:'Buscar materiais',hintText:'Descrição, categoria, unidade, origem ou observação',
      prefixIcon:const Icon(Icons.search),suffixIcon:q.isEmpty?null:IconButton(icon:const Icon(Icons.clear),
       onPressed:(){_search.clear();setState(()=>_query='');}),border:const OutlineInputBorder()))),
    Expanded(child:_items.isEmpty?const Center(child:Text('Nenhum material cadastrado neste projeto.')):
     list.isEmpty?const Center(child:Text('Nenhum material encontrado para esta busca.')):
     ListView.separated(padding:const EdgeInsets.fromLTRB(16,0,16,96),itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
      itemBuilder:(_,i){final m=list[i];final d=<String>[if(m.category.isNotEmpty)m.category,
       if(m.quantity!=null)'${m.quantity} ${m.unit}'.trim() else if(m.unit.isNotEmpty)m.unit,
       if(m.source.isNotEmpty)m.source];return Card(child:ListTile(title:Text(m.description),
        subtitle:d.isEmpty?null:Text(d.join(' • ')),trailing:const Icon(Icons.chevron_right),onTap:()=>_edit(m)));}))
   ]));}
}
class _MaterialDialog extends StatefulWidget{
 final ProfessionalMaterialRepository repository;final String projectId;final ProfessionalMaterial? material;final bool readOnly;
 const _MaterialDialog({required this.repository,required this.projectId,required this.material,required this.readOnly});
 @override State<_MaterialDialog> createState()=>_MaterialDialogState();
}
class _MaterialDialogState extends State<_MaterialDialog>{
 final _key=GlobalKey<FormState>();late final TextEditingController _description,_category,_unit,_quantity,_source,_notes;
 @override void initState(){super.initState();final m=widget.material;_description=TextEditingController(text:m?.description??'');
  _category=TextEditingController(text:m?.category??'');_unit=TextEditingController(text:m?.unit??'');
  _quantity=TextEditingController(text:m?.quantity?.toString()??'');_source=TextEditingController(text:m?.source??'');
  _notes=TextEditingController(text:m?.notes??'');}
 double? _n(String v)=>double.tryParse(v.trim().replaceAll(',','.'));
 InputDecoration _d(String l,String h)=>InputDecoration(labelText:l,hintText:h,border:const OutlineInputBorder());
 Future<void> _save()async{if(!_key.currentState!.validate())return;final now=DateTime.now().toUtc(),old=widget.material;
  await widget.repository.save(ProfessionalMaterial(id:old?.id??'material-${now.microsecondsSinceEpoch.toRadixString(36)}',
   projectId:widget.projectId,revision:old==null?1:old.revision+1,description:_description.text,category:_category.text,
   unit:_unit.text,quantity:_quantity.text.trim().isEmpty?null:_n(_quantity.text),source:_source.text,notes:_notes.text,
   createdAt:old?.createdAt??now,updatedAt:now));if(mounted)Navigator.pop(context,true);}
 @override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.material==null?'Novo material':widget.material!.description),
  content:SizedBox(width:560,child:Form(key:_key,child:SingleChildScrollView(child:Column(children:[
   TextFormField(controller:_description,readOnly:widget.readOnly,decoration:_d('Descrição','Identifique o material'),
    validator:(v)=>v==null||v.trim().isEmpty?'Informe a descrição.':null),
   const SizedBox(height:12),TextFormField(controller:_category,readOnly:widget.readOnly,
    decoration:_d('Categoria','Ex.: condutores, proteção, quadro, eletroduto')),
   const SizedBox(height:12),TextFormField(controller:_unit,readOnly:widget.readOnly,
    decoration:_d('Unidade','Ex.: m, un, peça, rolo')),
   const SizedBox(height:12),TextFormField(controller:_quantity,readOnly:widget.readOnly,
    keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:_d('Quantidade','Informe quando determinada'),
    validator:(v){if(v==null||v.trim().isEmpty)return null;final n=_n(v);return n==null||n<=0?'Informe uma quantidade maior que zero.':null;}),
   const SizedBox(height:12),TextFormField(controller:_source,readOnly:widget.readOnly,
    decoration:_d('Origem','Ex.: manual, estimada ou calculada')),
   const SizedBox(height:12),TextFormField(controller:_notes,readOnly:widget.readOnly,maxLines:3,
    decoration:_d('Observações','Informações técnicas complementares'))
  ])))),
  actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:Text(widget.readOnly?'Fechar':'Cancelar')),
   if(!widget.readOnly)FilledButton(onPressed:_save,child:const Text('Salvar'))]);
}
