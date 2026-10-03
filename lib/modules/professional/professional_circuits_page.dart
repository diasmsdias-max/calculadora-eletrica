import 'package:flutter/material.dart';

import '../../core/professional/professional_circuit.dart';
import '../../core/professional/professional_circuit_aggregation.dart';
import '../../core/professional/professional_circuit_repository.dart';
import '../../core/professional/professional_load.dart';
import '../../core/professional/professional_load_repository.dart';

class ProfessionalCircuitsPage extends StatefulWidget {
  final ProfessionalCircuitRepository repository;
  final ProfessionalLoadRepository loadsRepository;
  final String projectId;
  final bool readOnly;

  const ProfessionalCircuitsPage({
    super.key,
    required this.repository,
    required this.loadsRepository,
    required this.projectId,
    required this.readOnly,
  });

  @override
  State<ProfessionalCircuitsPage> createState() => _ProfessionalCircuitsPageState();
}

class _ProfessionalCircuitsPageState extends State<ProfessionalCircuitsPage> {
  List<ProfessionalCircuit> _circuits = const [];
  List<ProfessionalLoad> _loads = const [];
  bool _loading = true;
  final _search = TextEditingController();
  String _query = '';
  Map<String, List<String>> _loadIdsByCircuit = const {};
  static const _aggregator = ProfessionalCircuitAggregator();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final values = await Future.wait([
      widget.repository.getByProject(widget.projectId),
      widget.loadsRepository.getByProject(widget.projectId),
    ]);
    final circuits = values[0] as List<ProfessionalCircuit>;
    final relations = <String, List<String>>{};
    for (final circuit in circuits) {
      relations[circuit.id] = await widget.repository.getLoadIds(circuit.id);
    }
    if (!mounted) return;
    setState(() {
      _circuits = circuits;
      _loadIdsByCircuit = relations;
      _loads = values[1] as List<ProfessionalLoad>;
      _loading = false;
    });
  }

  Future<void> _edit([ProfessionalCircuit? circuit]) async {
    if (widget.readOnly && circuit == null) return;
    final selected = circuit == null
        ? <String>[]
        : await widget.repository.getLoadIds(circuit.id);
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CircuitDialog(
        repository: widget.repository,
        projectId: widget.projectId,
        circuit: circuit,
        availableLoads: _loads,
        selectedLoadIds: selected,
        loadOwnerById: {
          for (final entry in _loadIdsByCircuit.entries)
            for (final loadId in entry.value) loadId: entry.key,
        },
        readOnly: widget.readOnly,
      ),
    );
    if (saved == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final circuits = q.isEmpty
        ? _circuits
        : _circuits.where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.notes.toLowerCase().contains(q)).toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Circuitos')),
      floatingActionButton: widget.readOnly ? null : FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Novo circuito'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                labelText: 'Buscar circuitos',
                hintText: 'Nome, descrição ou observação',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.isEmpty ? null : IconButton(
                  onPressed: () { _search.clear(); setState(() => _query = ''); },
                  icon: const Icon(Icons.clear),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _circuits.isEmpty
                ? const Center(child: Text('Nenhum circuito cadastrado neste projeto.'))
                : circuits.isEmpty
                    ? const Center(child: Text('Nenhum circuito encontrado para esta busca.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: circuits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = circuits[i];
                          final loadIds = _loadIdsByCircuit[c.id] ?? const <String>[];
                          final linkedLoads = _loads.where((l) => loadIds.contains(l.id));
                          final aggregation = _aggregator.calculate(
                            circuit: c,
                            loads: linkedLoads,
                          );
                          final current = aggregation.designCurrentA;
                          return Card(
                            child: ListTile(
                              title: Text(c.name),
                              subtitle: Text([
                                if (c.description.isNotEmpty) c.description,
                                if (c.voltageV != null) '${c.voltageV} V',
                                if (c.phases != null) '${c.phases} fase(s)',
                                if (aggregation.linkedLoadCount > 0)
                                  '${aggregation.totalPowerW.toStringAsFixed(0)} W',
                                if (current != null)
                                  'I calc.: ${current.toStringAsFixed(2)} A',
                                if (current == null) aggregation.currentMessage,
                              ].join(' • ')),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _edit(c),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CircuitDialog extends StatefulWidget {
  final ProfessionalCircuitRepository repository;
  final String projectId;
  final ProfessionalCircuit? circuit;
  final List<ProfessionalLoad> availableLoads;
  final List<String> selectedLoadIds;
  final Map<String, String> loadOwnerById;
  final bool readOnly;

  const _CircuitDialog({
    required this.repository,
    required this.projectId,
    required this.circuit,
    required this.availableLoads,
    required this.selectedLoadIds,
    required this.loadOwnerById,
    required this.readOnly,
  });

  @override
  State<_CircuitDialog> createState() => _CircuitDialogState();
}

class _CircuitDialogState extends State<_CircuitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _voltage;
  late final TextEditingController _phases;
  late final TextEditingController _notes;
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final c = widget.circuit;
    _name = TextEditingController(text: c?.name ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _voltage = TextEditingController(text: c?.voltageV?.toString() ?? '');
    _phases = TextEditingController(text: c?.phases?.toString() ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _selected = widget.selectedLoadIds.toSet();
  }

  double? _number(String v) => double.tryParse(v.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().toUtc();
    final old = widget.circuit;
    final circuit = ProfessionalCircuit(
      id: old?.id ?? 'circuit-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId: widget.projectId,
      revision: old == null ? 1 : old.revision + 1,
      name: _name.text,
      description: _description.text,
      voltageV: _voltage.text.trim().isEmpty ? null : _number(_voltage.text),
      phases: _phases.text.trim().isEmpty ? null : int.tryParse(_phases.text.trim()),
      notes: _notes.text,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    await widget.repository.save(circuit);
    await widget.repository.replaceLoads(circuit.id, _selected);
    if (mounted) Navigator.of(context).pop(true);
  }

  InputDecoration _d(String label, String hint) =>
      InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.circuit == null ? 'Novo circuito' : widget.circuit!.name),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                readOnly: widget.readOnly,
                decoration: _d('Nome do circuito', 'Identifique o circuito no projeto'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do circuito.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _description, readOnly: widget.readOnly,
                decoration: _d('Descrição', 'Descreva a finalidade ou área atendida')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _voltage,
                readOnly: widget.readOnly,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _d('Tensão (V)', 'Informe quando definida para este circuito'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = _number(v);
                  return n == null || n <= 0 ? 'Informe uma tensão válida.' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phases,
                readOnly: widget.readOnly,
                keyboardType: TextInputType.number,
                decoration: _d('Número de fases', 'Informe 1, 2 ou 3 quando definido'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  return n == null || n < 1 || n > 3 ? 'Informe 1, 2 ou 3.' : null;
                },
              ),
              const SizedBox(height: 16),
              Text('Cargas do circuito', style: Theme.of(context).textTheme.titleMedium),
              if (widget.availableLoads.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Cadastre cargas no projeto para vinculá-las ao circuito.'),
                )
              else
                ...widget.availableLoads.map((load) {
                  final owner = widget.loadOwnerById[load.id];
                  final linkedElsewhere = owner != null && owner != widget.circuit?.id;
                  return CheckboxListTile(
                    value: _selected.contains(load.id),
                    onChanged: widget.readOnly || linkedElsewhere ? null : (checked) => setState(() {
                      if (checked == true) { _selected.add(load.id); } else { _selected.remove(load.id); }
                    }),
                    title: Text(load.name),
                    subtitle: Text([
                      if (load.category.isNotEmpty) load.category,
                      if (linkedElsewhere) 'Já vinculada a outro circuito',
                    ].join(' • ')),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              const SizedBox(height: 12),
              TextFormField(controller: _notes, readOnly: widget.readOnly, maxLines: 3,
                decoration: _d('Observações', 'Informações complementares do circuito')),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(false),
        child: Text(widget.readOnly ? 'Fechar' : 'Cancelar')),
      if (!widget.readOnly) FilledButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
}
