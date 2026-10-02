import 'package:flutter/material.dart';

import '../../core/professional/professional_load.dart';
import '../../core/professional/professional_load_repository.dart';

class ProfessionalLoadsPage extends StatefulWidget {
  final ProfessionalLoadRepository repository;
  final String projectId;
  final bool readOnly;

  const ProfessionalLoadsPage({
    super.key,
    required this.repository,
    required this.projectId,
    required this.readOnly,
  });

  @override
  State<ProfessionalLoadsPage> createState() => _ProfessionalLoadsPageState();
}

class _ProfessionalLoadsPageState extends State<ProfessionalLoadsPage> {
  List<ProfessionalLoad> _loads = const [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final loads = await widget.repository.getByProject(widget.projectId);
    if (!mounted) return;
    setState(() {
      _loads = loads;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProfessionalLoad> get _filteredLoads {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _loads;
    return _loads.where((load) =>
      load.name.toLowerCase().contains(query) ||
      load.category.toLowerCase().contains(query) ||
      load.notes.toLowerCase().contains(query)
    ).toList(growable: false);
  }

  Future<void> _edit([ProfessionalLoad? load]) async {
    if (widget.readOnly && load == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _LoadDialog(
        repository: widget.repository,
        projectId: widget.projectId,
        load: load,
        readOnly: widget.readOnly,
      ),
    );
    if (saved == true) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final loads = _filteredLoads;
    return Scaffold(
        appBar: AppBar(title: const Text('Cargas')),
        floatingActionButton: widget.readOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Nova carga'),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        labelText: 'Buscar cargas',
                        hintText: 'Nome, categoria ou observação',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty ? null : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _loads.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Nenhuma carga cadastrada neste projeto.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : loads.isEmpty
                    ? const Center(child: Text('Nenhuma carga encontrada para esta busca.'))
                    : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: loads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final load = loads[index];
                      return Card(
                        child: ListTile(
                          title: Text(load.name),
                          subtitle: Text([
                            if (load.category.isNotEmpty) load.category,
                            if (load.powerW > 0)
                              '${load.powerW.toStringAsFixed(0)} W por unidade',
                            if (load.quantity > 1) 'Quantidade: ${load.quantity}',
                          ].join(' • ')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _edit(load),
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

class _LoadDialog extends StatefulWidget {
  final ProfessionalLoadRepository repository;
  final String projectId;
  final ProfessionalLoad? load;
  final bool readOnly;

  const _LoadDialog({
    required this.repository,
    required this.projectId,
    required this.load,
    required this.readOnly,
  });

  @override
  State<_LoadDialog> createState() => _LoadDialogState();
}

class _LoadDialogState extends State<_LoadDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _quantity;
  late final TextEditingController _power;
  late final TextEditingController _voltage;
  late final TextEditingController _powerFactor;
  late final TextEditingController _simultaneity;
  late final TextEditingController _notes;
  String? _simultaneitySource;

  @override
  void initState() {
    super.initState();
    final load = widget.load;
    _name = TextEditingController(text: load?.name ?? '');
    _category = TextEditingController(text: load?.category ?? '');
    _quantity = TextEditingController(
      text: load == null ? '' : load.quantity.toString(),
    );
    _power = TextEditingController(
      text: load == null || load.powerW == 0 ? '' : load.powerW.toString(),
    );
    _voltage = TextEditingController(
      text: load == null || load.voltageV == 0 ? '' : load.voltageV.toString(),
    );
    _powerFactor = TextEditingController(
      text: load?.powerFactor?.toString() ?? '',
    );
    _simultaneity = TextEditingController(
      text: load?.simultaneityFactor?.toString() ?? '',
    );
    _simultaneitySource = load?.simultaneitySource;
    _notes = TextEditingController(text: load?.notes ?? '');
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now().toUtc();
    final current = widget.load;
    final load = ProfessionalLoad(
      id: current?.id ?? 'load-${now.microsecondsSinceEpoch.toRadixString(36)}',
      projectId: widget.projectId,
      revision: current == null ? 1 : current.revision + 1,
      name: _name.text,
      category: _category.text,
      quantity: int.tryParse(_quantity.text.trim()) ?? 1,
      powerW: _number(_power.text) ?? 0,
      voltageV: _number(_voltage.text) ?? 0,
      powerFactor: _powerFactor.text.trim().isEmpty
          ? null
          : _number(_powerFactor.text),
      simultaneityFactor: _number(_simultaneity.text),
      simultaneitySource: _simultaneitySource ?? 'professional',
      simultaneityBasis: current?.simultaneityBasis ?? '',
      notes: _notes.text,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    ).normalized();
    await widget.repository.save(load);
    if (mounted) Navigator.of(context).pop(true);
  }

  InputDecoration _decoration(String label, String hint) =>
      InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.load == null ? 'Nova carga' : widget.load!.name),
        content: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    readOnly: widget.readOnly,
                    decoration: _decoration('Nome da carga', 'Identifique o equipamento ou ponto de utilização'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome da carga.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _category,
                    readOnly: widget.readOnly,
                    decoration: _decoration('Categoria', 'Ex.: iluminação, tomada, motor ou climatização'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantity,
                    readOnly: widget.readOnly,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Quantidade', 'Informe quantas cargas iguais serão consideradas'),
                    validator: (v) {
                      final value = int.tryParse(v?.trim() ?? '');
                      return value == null || value < 1 ? 'Informe uma quantidade válida.' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _power,
                    readOnly: widget.readOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration('Potência unitária (W)', 'Informe a potência nominal de uma unidade'),
                    validator: (v) {
                      final value = _number(v ?? '');
                      return value == null || value <= 0 ? 'Informe uma potência válida.' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _voltage,
                    readOnly: widget.readOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration('Tensão (V)', 'Informe a tensão de alimentação'),
                    validator: (v) {
                      final value = _number(v ?? '');
                      return value == null || value <= 0 ? 'Informe uma tensão válida.' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _powerFactor,
                    readOnly: widget.readOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration('Fator de potência', 'Informe quando conhecido, usando valor entre 0 e 1'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final value = _number(v);
                      return value == null || value <= 0 || value > 1
                          ? 'Use um valor maior que 0 e até 1.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _simultaneity,
                    readOnly: widget.readOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _decoration(
                      'Fator de simultaneidade (FS)',
                      'Informe um valor maior que 0 e até 1',
                    ),
                    onChanged: widget.readOnly ? null : (_) => _simultaneitySource = 'professional',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o FS ou utilize Estimar FS.';
                      }
                      final value = _number(v);
                      return value == null || value <= 0 || value > 1
                          ? 'Use um valor maior que 0 e até 1.'
                          : null;
                    },
                  ),
                  if (!widget.readOnly)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Assistente Estimar FS: perguntas guiadas serão ativadas na próxima etapa.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Estimar FS'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    readOnly: widget.readOnly,
                    maxLines: 3,
                    decoration: _decoration('Observações', 'Informações complementares da carga'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.readOnly ? 'Fechar' : 'Cancelar'),
          ),
          if (!widget.readOnly)
            FilledButton(onPressed: _save, child: const Text('Salvar')),
        ],
      );
}
