import 'package:flutter/material.dart';
import '../../core/formatters/technical_format.dart';
import '../../core/calculations/load_survey_calculator.dart';
import '../../core/calculations/power_calculator.dart';
import '../../core/database/project_record.dart';
import '../../core/projects/project_record_saver.dart';

class LoadSurveyPage extends StatefulWidget {
  const LoadSurveyPage({super.key});
  @override
  State<LoadSurveyPage> createState() => _LoadSurveyPageState();
}

class _LoadSurveyPageState extends State<LoadSurveyPage> {
  final List<LoadItem> items = [];
  int daysPerMonth = 30;
  AcSystem system = AcSystem.threePhase;
  final voltage = TextEditingController(text: '220');

  double? get parsedVoltage =>
      double.tryParse(voltage.text.trim().replaceAll(',', '.'));

  double get voltageValue => parsedVoltage ?? 0;

  LoadSurveyResult get result => LoadSurveyCalculator.calculate(
        items,
        daysPerMonth: daysPerMonth,
        system: parsedVoltage != null && parsedVoltage! > 0 ? system : null,
        voltageV: parsedVoltage != null && parsedVoltage! > 0 ? parsedVoltage : null,
      );

  Future<void> _saveToProject() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma carga antes de salvar.')),
      );
      return;
    }
    if (parsedVoltage == null || parsedVoltage! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma tensão válida antes de salvar.')),
      );
      return;
    }
    final totals = result;
    await ProjectRecordSaver.save(
      context,
      type: ProjectRecordType.loadSurvey,
      title: 'Levantamento de Cargas — ${items.length} ${items.length == 1 ? 'item' : 'itens'}',
      summary: '${TechnicalFormat.number(totals.installedKw)} kW instalados | demanda ${TechnicalFormat.number(totals.demandKw)} kW',
      data: {
        'system': system.name,
        'voltageV': voltageValue,
        'daysPerMonth': daysPerMonth,
        'loads': items.map((i) => {
          'description': i.description,
          'unitPowerKw': i.unitPowerKw,
          'quantity': i.quantity,
          'powerFactor': i.powerFactor,
          'simultaneity': i.simultaneity,
          'hoursPerDay': i.hoursPerDay,
        }).toList(),
        'installedKw': totals.installedKw,
        'demandKw': totals.demandKw,
        'apparentKva': totals.apparentKva,
        'demandCurrentA': totals.demandCurrentA,
        'dailyKwh': totals.dailyKwh,
        'monthlyKwh': totals.monthlyKwh,
      },
    );
  }

  Future<void> _openEditor({int? index}) async {
    final item = index == null ? null : items[index];
    final edited = await showDialog<LoadItem>(
      context: context,
      builder: (_) => _LoadEditorDialog(initial: item),
    );
    if (edited == null) return;
    setState(() {
      if (index == null) {
        items.add(edited);
      } else {
        items[index] = edited;
      }
    });
  }

  void _remove(int index) {
    setState(() => items.removeAt(index));
  }

  @override
  void dispose() {
    voltage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = result;
    return Scaffold(
      appBar: AppBar(title: const Text('Levantamento de Cargas')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text('Cargas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhuma carga adicionada. Use “Adicionar carga” para iniciar o levantamento.'),
                ),
              )
            else
              ...List.generate(items.length, (index) {
                final item = items[index];
                final itemResult = LoadSurveyCalculator.calculate([item], daysPerMonth: daysPerMonth);
                return Card(
                  child: ListTile(
                    title: Text(item.description.isEmpty ? 'Carga ${index + 1}' : item.description),
                    subtitle: Text(
                      '${TechnicalFormat.number(item.unitPowerKw * 1000, decimals: 0)} W x ${item.quantity}  |  '
                      'Demanda ${TechnicalFormat.number(itemResult.demandKw)} kW  |  '
                      '${TechnicalFormat.number(item.hoursPerDay, decimals: 1)} h/dia',
                    ),
                    isThreeLine: true,
                    onTap: () => _openEditor(index: index),
                    trailing: IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(index),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('ADICIONAR CARGA'),
            ),
            const SizedBox(height: 20),
            Text('Instalação', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<AcSystem>(
              initialValue: system,
              decoration: const InputDecoration(labelText: 'Sistema'),
              items: const [
                DropdownMenuItem(value: AcSystem.singlePhase, child: Text('Monofásico')),
                DropdownMenuItem(value: AcSystem.twoPhase, child: Text('Bifásico')),
                DropdownMenuItem(value: AcSystem.threePhase, child: Text('Trifásico')),
              ],
              onChanged: (v) => setState(() => system = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: voltage,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tensão da instalação (V)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text('Resumo', style: Theme.of(context).textTheme.titleLarge)),
                DropdownButton<int>(
                  value: daysPerMonth,
                  items: const [20, 22, 25, 30, 31]
                      .map((d) => DropdownMenuItem(value: d, child: Text('$d dias/mês')))
                      .toList(),
                  onChanged: (v) => setState(() => daysPerMonth = v!),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _result('Potência instalada', totals.installedKw, 'kW'),
            _result('Demanda estimada', totals.demandKw, 'kW'),
            _result('Potência aparente da demanda', totals.apparentKva, 'kVA'),
            if (totals.demandCurrentA != null)
              _result('Corrente estimada da demanda', totals.demandCurrentA!, 'A'),
            _result('Consumo diário', totals.dailyKwh, 'kWh'),
            _result('Consumo mensal', totals.monthlyKwh, 'kWh'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: items.isEmpty ? null : _saveToProject,
              icon: const Icon(Icons.save_outlined),
              label: const Text('SALVAR NO PROJETO'),
            ),
            const SizedBox(height: 12),
            const Text(
              'A demanda usa o fator de simultaneidade informado em cada carga. '
              'O consumo considera a potência instalada de cada item durante suas horas de uso.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _result(String label, double value, String unit) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(
        '${TechnicalFormat.number(value)} $unit',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}

class _LoadEditorDialog extends StatefulWidget {
  final LoadItem? initial;
  const _LoadEditorDialog({this.initial});

  @override
  State<_LoadEditorDialog> createState() => _LoadEditorDialogState();
}

class _LoadEditorDialogState extends State<_LoadEditorDialog> {
  late final TextEditingController description;
  late final TextEditingController powerW;
  late final TextEditingController quantity;
  late final TextEditingController powerFactor;
  late final TextEditingController simultaneityPercent;
  late final TextEditingController hoursPerDay;
  String? error;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    description = TextEditingController(text: i?.description ?? '');
    powerW = TextEditingController(text: i == null ? '' : (i.unitPowerKw * 1000).toStringAsFixed(0));
    quantity = TextEditingController(text: (i?.quantity ?? 1).toString());
    powerFactor = TextEditingController(text: (i?.powerFactor ?? 0.92).toString().replaceAll('.', ','));
    simultaneityPercent = TextEditingController(text: ((i?.simultaneity ?? 1) * 100).toStringAsFixed(0));
    hoursPerDay = TextEditingController(text: (i?.hoursPerDay ?? 8).toString().replaceAll('.', ','));
  }

  double _n(String v) => double.parse(v.trim().replaceAll(',', '.'));

  void _save() {
    try {
      final item = LoadItem(
        description: description.text.trim(),
        unitPowerKw: _n(powerW.text) / 1000,
        quantity: int.parse(quantity.text.trim()),
        powerFactor: _n(powerFactor.text),
        simultaneity: _n(simultaneityPercent.text) / 100,
        hoursPerDay: _n(hoursPerDay.text),
      );
      LoadSurveyCalculator.calculate([item]);
      Navigator.of(context).pop(item);
    } catch (_) {
      setState(() => error = 'Confira os valores informados.');
    }
  }

  @override
  void dispose() {
    for (final c in [description, powerW, quantity, powerFactor, simultaneityPercent, hoursPerDay]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Adicionar carga' : 'Editar carga'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 12),
          _field(powerW, 'Potência unitária (W)'),
          const SizedBox(height: 12),
          _field(quantity, 'Quantidade', decimal: false),
          const SizedBox(height: 12),
          _field(powerFactor, 'Fator de potência'),
          const SizedBox(height: 12),
          _field(simultaneityPercent, 'Simultaneidade (%)'),
          const SizedBox(height: 12),
          _field(hoursPerDay, 'Horas de uso por dia'),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
      FilledButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );

  Widget _field(TextEditingController c, String label, {bool decimal = true}) => TextField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    decoration: InputDecoration(labelText: label),
  );
}
