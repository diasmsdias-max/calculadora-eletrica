import 'package:flutter/material.dart';

import '../../core/professional/professional_load.dart';
import '../../core/professional/professional_load_repository.dart';
import '../../core/professional/professional_simultaneity_estimator.dart';

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
  String _simultaneityBasis = '';

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
    _simultaneityBasis = load?.simultaneityBasis ?? '';
    _notes = TextEditingController(text: load?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _quantity.dispose();
    _power.dispose();
    _voltage.dispose();
    _powerFactor.dispose();
    _simultaneity.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  Future<void> _estimateSimultaneity() async {
    final quantity = int.tryParse(_quantity.text.trim());
    final unitPower = _number(_power.text);
    if (quantity == null || quantity < 1 || unitPower == null || unitPower <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe primeiro a quantidade e a potência unitária.'),
        ),
      );
      return;
    }

    final estimate = await showDialog<ProfessionalSimultaneityEstimate>(
      context: context,
      builder: (_) => _SimultaneityEstimateDialog(
        quantity: quantity,
        unitPowerW: unitPower,
      ),
    );
    if (estimate == null || !mounted) return;
    setState(() {
      _simultaneity.text = estimate.factor.toStringAsFixed(3);
      _simultaneitySource = 'visEstimate';
      _simultaneityBasis = estimate.basis;
    });
  }

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
      simultaneityBasis: _simultaneityBasis,
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
                    onChanged: widget.readOnly ? null : (_) {
                      _simultaneitySource = 'professional';
                      _simultaneityBasis = '';
                    },
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
                        onPressed: _estimateSimultaneity,
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


enum _EstimateMethod { quantity, demand, noDiversity }

class _SimultaneityEstimateDialog extends StatefulWidget {
  final int quantity;
  final double unitPowerW;

  const _SimultaneityEstimateDialog({
    required this.quantity,
    required this.unitPowerW,
  });

  @override
  State<_SimultaneityEstimateDialog> createState() =>
      _SimultaneityEstimateDialogState();
}

class _SimultaneityEstimateDialogState
    extends State<_SimultaneityEstimateDialog> {
  final _value = TextEditingController();
  _EstimateMethod _method = _EstimateMethod.quantity;
  String? _error;

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _calculate() {
    const estimator = ProfessionalSimultaneityEstimator();
    try {
      late final ProfessionalSimultaneityEstimate result;
      switch (_method) {
        case _EstimateMethod.quantity:
          final simultaneous = int.tryParse(_value.text.trim());
          if (simultaneous == null) throw ArgumentError();
          result = estimator.bySimultaneousQuantity(
            totalQuantity: widget.quantity,
            simultaneousQuantity: simultaneous,
            unitPowerW: widget.unitPowerW,
          );
        case _EstimateMethod.demand:
          final demand = _number(_value.text);
          if (demand == null) throw ArgumentError();
          result = estimator.bySimultaneousDemand(
            totalQuantity: widget.quantity,
            unitPowerW: widget.unitPowerW,
            simultaneousPowerW: demand,
          );
        case _EstimateMethod.noDiversity:
          result = estimator.withoutDiversity(
            totalQuantity: widget.quantity,
            unitPowerW: widget.unitPowerW,
          );
      }
      _showResult(result);
    } on ArgumentError {
      setState(() => _error = 'Confira os valores informados para a estimativa.');
    }
  }

  Future<void> _showResult(ProfessionalSimultaneityEstimate result) async {
    final adopt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estimativa de simultaneidade'),
        content: Text(
          'FS estimado: ${result.factor.toStringAsFixed(3)}\n'
          'Carga instalada: ${result.installedPowerW.toStringAsFixed(1)} W\n'
          'Demanda simultânea: ${result.simultaneousPowerW.toStringAsFixed(1)} W\n\n'
          '${result.basis}\n\n'
          'Revise a estimativa antes de adotá-la.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Adotar estimativa'),
          ),
        ],
      ),
    );
    if (adopt == true && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final installed = widget.quantity * widget.unitPowerW;
    return AlertDialog(
      title: const Text('Estimar FS'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Carga instalada considerada: ${installed.toStringAsFixed(1)} W. '
              'Escolha como deseja estimar a simultaneidade.',
            ),
            RadioGroup<_EstimateMethod>(
              groupValue: _method,
              onChanged: (value) => setState(() {
                _method = value ?? _method;
                _value.clear();
                _error = null;
              }),
              child: Column(
                children: [
                  RadioListTile<_EstimateMethod>(
                    value: _EstimateMethod.quantity,
                    title: const Text('Quantidade simultânea'),
                    subtitle: Text(
                      'Informe quantas das ${widget.quantity} unidades podem operar ao mesmo tempo.',
                    ),
                  ),
                  RadioListTile<_EstimateMethod>(
                    value: _EstimateMethod.demand,
                    title: const Text('Demanda simultânea conhecida'),
                    subtitle: const Text('Informe a potência máxima simultânea estimada em W.'),
                  ),
                  RadioListTile<_EstimateMethod>(
                    value: _EstimateMethod.noDiversity,
                    title: const Text('Considerar 100% da carga'),
                    subtitle: const Text('Opção conservadora, sem aplicar diversidade.'),
                  ),
                ],
              ),
            ),
            if (_method != _EstimateMethod.noDiversity)
              TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _method == _EstimateMethod.quantity
                      ? 'Unidades simultâneas'
                      : 'Demanda simultânea (W)',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
              ),
            if (_method == _EstimateMethod.noDiversity && _error != null)
              Text(_error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _calculate,
          child: const Text('Calcular estimativa'),
        ),
      ],
    );
  }
}
