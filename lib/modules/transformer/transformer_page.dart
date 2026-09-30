import 'package:flutter/material.dart';
import '../../core/formatters/technical_format.dart';
import '../../core/calculations/power_calculator.dart';
import '../../core/calculations/transformer_calculator.dart';
import '../../core/database/project_record.dart';
import '../../core/projects/project_record_saver.dart';

enum TransformerLoadUnit { kw, kva }

class TransformerPage extends StatefulWidget {
  const TransformerPage({super.key});
  @override
  State<TransformerPage> createState() => _TransformerPageState();
}

class _TransformerPageState extends State<TransformerPage> {
  final ratedKva = TextEditingController(text: '10');
  final voltage = TextEditingController(text: '220');
  final powerFactor = TextEditingController(text: '0,85');
  final load = TextEditingController(text: '0');

  AcSystem system = AcSystem.threePhase;
  TransformerLoadUnit loadUnit = TransformerLoadUnit.kw;
  TransformerResult? result;
  String? error;

  double _n(String value) => double.parse(value.trim().replaceAll(',', '.'));

  Future<void> _saveToProject() async {
    final r = result;
    if (r == null) return;
    final loadValue = _n(load.text);
    await ProjectRecordSaver.save(
      context,
      type: ProjectRecordType.transformer,
      title: 'Transformador — ${TechnicalFormat.number(_n(ratedKva.text))} kVA',
      summary: '${TechnicalFormat.number(r.loadPercent, decimals: 1)}% carregado | ${r.meetsLoad ? 'ATENDE' : 'NÃO ATENDE'}',
      data: {
        'ratedKva': _n(ratedKva.text),
        'system': system.name,
        'voltageV': _n(voltage.text),
        'loadUnit': loadUnit.name,
        'loadValue': loadValue,
        'powerFactor': _n(powerFactor.text),
        'availableCurrentA': r.availableCurrentA,
        'availableActivePowerKw': r.availableActivePowerKw,
        'loadKva': r.loadKva,
        'loadPercent': r.loadPercent,
        'remainingKva': r.remainingKva,
        'meetsLoad': r.meetsLoad,
      },
    );
  }

  void _calculate() {
    try {
      final loadValue = _n(load.text);
      final value = TransformerCalculator.calculate(
        ratedKva: _n(ratedKva.text),
        system: system,
        voltageV: _n(voltage.text),
        loadPowerFactor: _n(powerFactor.text),
        loadKw: loadUnit == TransformerLoadUnit.kw ? loadValue : 0,
        loadKva: loadUnit == TransformerLoadUnit.kva ? loadValue : null,
      );
      setState(() { result = value; error = null; });
    } catch (_) {
      setState(() { result = null; error = 'Confira os valores informados.'; });
    }
  }

  @override
  void dispose() {
    ratedKva.dispose();
    voltage.dispose();
    powerFactor.dispose();
    load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transformador')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Dados do transformador', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _field(ratedKva, 'Potência nominal (kVA)'),
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
          _field(voltage, 'Tensão secundária (V)'),
          const SizedBox(height: 20),
          Text('Carga a analisar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<TransformerLoadUnit>(
            segments: const [
              ButtonSegment(value: TransformerLoadUnit.kw, label: Text('kW')),
              ButtonSegment(value: TransformerLoadUnit.kva, label: Text('kVA')),
            ],
            selected: {loadUnit},
            onSelectionChanged: (v) => setState(() { loadUnit = v.first; result = null; }),
          ),
          const SizedBox(height: 12),
          _field(load, loadUnit == TransformerLoadUnit.kw ? 'Carga ativa (kW)' : 'Carga aparente (kVA)'),
          const SizedBox(height: 12),
          _field(powerFactor, 'Fator de potência da carga'),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('CALCULAR')),
          if (error != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (result != null) ...[
            const SizedBox(height: 20),
            Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _status(result!.meetsLoad),
            const SizedBox(height: 8),
            _result('Corrente nominal disponível', result!.availableCurrentA, 'A'),
            _result('Potência ativa disponível', result!.availableActivePowerKw, 'kW'),
            _result('Carga equivalente', result!.loadKva, 'kVA'),
            _result('Carregamento do transformador', result!.loadPercent, '%'),
            _result('Capacidade restante', result!.remainingKva, 'kVA'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saveToProject,
              icon: const Icon(Icons.save_outlined),
              label: const Text('SALVAR NO PROJETO'),
            ),
            const SizedBox(height: 12),
            const Text('A indicação ATENDE considera apenas a capacidade nominal em regime permanente. Partidas de motores e quedas de tensão devem ser analisadas separadamente.'),
          ],
        ],
      ),
    ),
  );

  Widget _field(TextEditingController controller, String label) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );

  Widget _status(bool ok) => Card(
    child: ListTile(
      leading: Icon(ok ? Icons.check_circle : Icons.warning_amber),
      title: Text(ok ? 'ATENDE EM REGIME PERMANENTE' : 'NÃO ATENDE EM REGIME PERMANENTE'),
    ),
  );

  Widget _result(String label, double value, String unit) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text('${TechnicalFormat.number(value)} $unit', style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
