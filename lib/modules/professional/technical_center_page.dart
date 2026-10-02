import 'package:flutter/material.dart';
import '../../core/technical_center/technical_center_actions.dart';
import '../../core/technical_center/technical_document.dart';
import '../../core/technical_center/technical_document_repository.dart';
import 'technical_pdf_viewer_page.dart';

class TechnicalCenterPage extends StatefulWidget {
  final TechnicalDocumentRepository repository;
  final TechnicalCenterActions? actions;
  const TechnicalCenterPage({super.key, required this.repository, this.actions});
  @override State<TechnicalCenterPage> createState()=>_TechnicalCenterPageState();
}

class _TechnicalCenterPageState extends State<TechnicalCenterPage> {
  List<TechnicalDocument> _documents=const[]; String _query=''; TechnicalDocumentCategory? _category; bool _busy=false;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { final docs=await widget.repository.list(); if(mounted)setState(()=>_documents=docs); }
  List<TechnicalDocument> get _filtered {
    final q=_query.trim().toLowerCase();
    return _documents.where((d){
      final categoryOk=_category==null||d.category==_category;
      final value=[d.title,d.manufacturer,d.equipmentType,d.model,d.description].join(' ').toLowerCase();
      return categoryOk&&(q.isEmpty||value.contains(q));
    }).toList();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Central Técnica VIS'),actions:[if(widget.actions!=null)IconButton(tooltip:'Sincronizar catálogo',onPressed:_busy?null:_sync,icon:const Icon(Icons.sync))]),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Documentação técnica para consulta rápida em campo. Baixe antes do atendimento o que precisar usar sem internet.'),
      const SizedBox(height:12),
      TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Buscar fabricante, equipamento, modelo ou documento'),onChanged:(v)=>setState(()=>_query=v)),
      const SizedBox(height:12),
      Wrap(spacing:8,runSpacing:8,children:[
        FilterChip(label:const Text('Todos'),selected:_category==null,onSelected:(_)=>setState(()=>_category=null)),
        ...TechnicalDocumentCategory.values.map((c)=>FilterChip(label:Text(_label(c)),selected:_category==c,onSelected:(_)=>setState(()=>_category=c))),
      ]),
      const SizedBox(height:12),
      if(_filtered.isEmpty) const Card(child:ListTile(leading:Icon(Icons.library_books_outlined),title:Text('Nenhum documento no catálogo'),subtitle:Text('O catálogo será sincronizado com o servidor VIS. Documentos baixados permanecerão disponíveis offline.'))),
      ..._filtered.map((d)=>Card(child:ListTile(
        leading:Icon(d.isAvailableOffline?Icons.offline_pin_outlined:Icons.cloud_outlined),
        title:Text(d.title),
        subtitle:Text([if(d.manufacturer.isNotEmpty)d.manufacturer,if(d.equipmentType.isNotEmpty)d.equipmentType,if(d.model.isNotEmpty)d.model,d.isAvailableOffline?'Disponível offline':'Disponível para download'].join(' • ')),
        trailing:_actions(context,d),
      ))),
    ]),
  );
  Future<void> _sync() async {
    final actions=widget.actions;
    if(actions==null)return;
    setState(()=>_busy=true);
    try {
      await actions.syncCatalog();
      await _load();
    } finally {
      if(mounted)setState(()=>_busy=false);
    }
  }

  Future<void> _download(TechnicalDocument document) async {
    final actions=widget.actions;
    if(actions==null)return;
    setState(()=>_busy=true);
    try {
      await actions.download(document);
      await _load();
    } finally {
      if(mounted)setState(()=>_busy=false);
    }
  }

  Future<void> _remove(TechnicalDocument document) async {
    final actions=widget.actions;
    if(actions==null)return;
    setState(()=>_busy=true);
    try {
      await actions.removeLocalCopy(document);
      await _load();
    } finally {
      if(mounted)setState(()=>_busy=false);
    }
  }

  Widget? _actions(BuildContext context, TechnicalDocument document) {
    final isPdf = document.mimeType.toLowerCase() == 'application/pdf' ||
        document.fileName.toLowerCase().endsWith('.pdf');
    if (document.isAvailableOffline &&
        isPdf &&
        document.localPath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (document.keepOffline) const Icon(Icons.push_pin_outlined),
          IconButton(
            tooltip: 'Abrir no VIS',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TechnicalPdfViewerPage(
                    title: document.title,
                    localPath: document.localPath!,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }
    if (widget.actions != null && !document.isAvailableOffline) {
      return IconButton(
        tooltip: 'Baixar para offline',
        onPressed: _busy ? null : () => _download(document),
        icon: const Icon(Icons.download_outlined),
      );
    }
    if (widget.actions != null && document.isAvailableOffline) {
      return IconButton(
        tooltip: 'Remover download',
        onPressed: _busy ? null : () => _remove(document),
        icon: const Icon(Icons.delete_outline),
      );
    }
    return document.keepOffline ? const Icon(Icons.push_pin_outlined) : null;
  }

  String _label(TechnicalDocumentCategory c)=>switch(c){
    TechnicalDocumentCategory.manufacturerManual=>'Manuais',
    TechnicalDocumentCategory.controlPanel=>'Quadros de Comandos',
    TechnicalDocumentCategory.technicalReference=>'Referências',
    TechnicalDocumentCategory.other=>'Outros',
  };
}
