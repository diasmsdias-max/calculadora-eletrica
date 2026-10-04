import 'package:flutter/material.dart';
import '../../core/professional/professional_memorial.dart';
import '../../core/professional/professional_memorial_repository.dart';
import '../../core/professional/professional_memorial_consolidator.dart';
import '../../core/professional/professional_board_repository.dart';
import '../../core/professional/professional_circuit_repository.dart';
import '../../core/professional/professional_load_repository.dart';
import '../../core/professional/professional_sizing_repository.dart';
import '../../core/professional/professional_protection_repository.dart';

class ProfessionalMemorialPage extends StatefulWidget {
  final ProfessionalMemorialRepository repository;
  final ProfessionalBoardRepository boardsRepository;
  final ProfessionalCircuitRepository circuitsRepository;
  final ProfessionalLoadRepository loadsRepository;
  final ProfessionalSizingRepository sizingRepository;
  final ProfessionalProtectionRepository protectionsRepository;
  final String projectId;
  final bool readOnly;
  final String? boardId;
  const ProfessionalMemorialPage({super.key, required this.repository,required this.boardsRepository,
    required this.circuitsRepository,required this.loadsRepository,required this.sizingRepository,
    required this.protectionsRepository,required this.projectId, required this.readOnly,this.boardId});
  @override State<ProfessionalMemorialPage> createState() => _ProfessionalMemorialPageState();
}

class _ProfessionalMemorialPageState extends State<ProfessionalMemorialPage> {
  final _title = TextEditingController();
  final _scope = TextEditingController();
  final _criteria = TextEditingController();
  final _conclusions = TextEditingController();
  final _notes = TextEditingController();
  ProfessionalMemorial? _current;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _title.dispose(); _scope.dispose(); _criteria.dispose(); _conclusions.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.boardId != null) {
      final boards = await widget.boardsRepository.getByProject(widget.projectId);
      final board = boards.where((b) => b.id == widget.boardId).firstOrNull;
      if (board != null) {
        final circuitIds = await widget.boardsRepository.getCircuitIds(board.id);
        final circuits = await widget.circuitsRepository.getByProject(widget.projectId);
        final loads = await widget.loadsRepository.getByProject(widget.projectId);
        final sizing = await widget.sizingRepository.getByProject(widget.projectId);
        final protections = await widget.protectionsRepository.getByProject(widget.projectId);
        final selectedCircuits = circuits.where((c) => circuitIds.contains(c.id)).toList();
        final selectedIds = selectedCircuits.map((c) => c.id).toSet();
        final loadIds = <String>{};
        for (final id in selectedIds) {
          loadIds.addAll(await widget.circuitsRepository.getLoadIds(id));
        }
        final snapshot = const ProfessionalMemorialConsolidator().build(
          boards:[board],circuits:selectedCircuits,
          loads:loads.where((l) => loadIds.contains(l.id)),
          sizing:sizing.where((s) => selectedIds.contains(s.circuitId)),
          protections:protections.where((p) => selectedIds.contains(p.circuitId)));
        _title.text = 'Memorial técnico — ${board.name}';
        _scope.text = snapshot.scope;
        _criteria.text = snapshot.criteria;
      }
      if (mounted) setState(() => _loading = false);
      return;
    }
    final m = await widget.repository.getByProject(widget.projectId);
    if (!mounted) return;
    _current = m;
    _title.text = m?.title ?? '';
    _scope.text = m?.scope ?? '';
    _criteria.text = m?.criteria ?? '';
    _conclusions.text = m?.conclusions ?? '';
    _notes.text = m?.notes ?? '';
    setState(() => _loading = false);
  }

  Future<void> _consolidate() async {
    final v=await Future.wait([
      widget.boardsRepository.getByProject(widget.projectId),
      widget.circuitsRepository.getByProject(widget.projectId),
      widget.loadsRepository.getByProject(widget.projectId),
      widget.sizingRepository.getByProject(widget.projectId),
      widget.protectionsRepository.getByProject(widget.projectId),
    ]);
    final snapshot=const ProfessionalMemorialConsolidator().build(
      boards:v[0] as dynamic,circuits:v[1] as dynamic,loads:v[2] as dynamic,
      sizing:v[3] as dynamic,protections:v[4] as dynamic);
    if(!mounted)return;
    setState((){_scope.text=snapshot.scope;_criteria.text=snapshot.criteria;});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:Text('Dados técnicos consolidados. Revise e salve o memorial.')));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final old = _current;
    final memorial = ProfessionalMemorial(
      id: old?.id ?? 'memorial-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId: widget.projectId,
      revision: old == null ? 1 : old.revision + 1,
      title: _title.text,
      scope: _scope.text,
      criteria: _criteria.text,
      conclusions: _conclusions.text,
      notes: _notes.text,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    await widget.repository.save(memorial);
    if (!mounted) return;
    _current = memorial;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memorial salvo.')));
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label, hintText: hint, alignLabelWithHint: true, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.boardId==null?'Memorial':'Memorial do quadro')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.boardId==null?'Memorial técnico do projeto':'Memorial técnico do quadro', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Registre apenas informações confirmadas. Campos vazios permanecem indefinidos.'),
        const SizedBox(height: 16),
        TextField(controller: _title, readOnly: widget.readOnly,
          decoration: _decoration('Título', 'Identifique o memorial ou documento técnico')),
        const SizedBox(height: 12),
        TextField(controller: _scope, readOnly: widget.readOnly, minLines: 4, maxLines: 8,
          decoration: _decoration('Objetivo / escopo', 'Descreva o objeto, limites e abrangência do projeto')),
        const SizedBox(height: 12),
        TextField(controller: _criteria, readOnly: widget.readOnly, minLines: 5, maxLines: 12,
          decoration: _decoration('Critérios adotados', 'Registre métodos, hipóteses, referências e critérios técnicos')),
        const SizedBox(height: 12),
        TextField(controller: _conclusions, readOnly: widget.readOnly, minLines: 4, maxLines: 10,
          decoration: _decoration('Conclusões', 'Registre conclusões técnicas confirmadas')),
        const SizedBox(height: 12),
        TextField(controller: _notes, readOnly: widget.readOnly, minLines: 3, maxLines: 8,
          decoration: _decoration('Observações', 'Informações complementares')),
        if (!widget.readOnly) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed:_consolidate,icon:const Icon(Icons.auto_awesome_outlined),
            label:const Text('Atualizar dados pelo VIS')),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Salvando...' : 'Salvar memorial'),
          ),
        ],
        const SizedBox(height: 32),
      ],
    ),
  );
}
