import 'package:flutter/material.dart';
import '../../core/professional/professional_memorial.dart';
import '../../core/professional/professional_memorial_repository.dart';

class ProfessionalMemorialPage extends StatefulWidget {
  final ProfessionalMemorialRepository repository;
  final String projectId;
  final bool readOnly;
  const ProfessionalMemorialPage({super.key, required this.repository, required this.projectId, required this.readOnly});
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
    appBar: AppBar(title: const Text('Memorial')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Memorial técnico do projeto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
