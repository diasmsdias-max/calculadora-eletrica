import 'package:flutter/material.dart';
import '../../core/calculations/power_calculator.dart';
import '../../core/calculations/voltage_drop_calculator.dart';

class VoltageDropPage extends StatefulWidget {
  const VoltageDropPage({super.key});
  @override
  State<VoltageDropPage> createState() => _VoltageDropPageState();
}

class _VoltageDropPageState extends State<VoltageDropPage> {
  final voltage = TextEditingController(text: '220');
  final current = TextEditingController(text: '20');
  final length = TextEditingController(text: '30');
  final section = TextEditingController(text: '4');
  final powerFactor = TextEditingController(text: '0,92');
  final maxDrop = TextEditingController(text: '4');

  AcSystem system = AcSystem.twoPhase;
  ConductorMaterial material = ConductorMaterial.copper;
  VoltageDropResult? result;
  String? error;

  double _n(String v) => double.parse(v.trim().replaceAll(',', '.'));

  void _calculate() {
    try {
      final r = VoltageDropCalculator.calculate(
        system: system,
        voltageV: _n(voltage.text),
        currentA: _n(current.text),
        lengthM: _n(length.text),
        sectionMm2: _n(section.text),
        material: material,
        powerFactor: _n(powerFactor.text),
        maxDropPercent: _n(maxDrop.text),
      );
      setState(() { result = r; error = null; });
    } catch (_) {
      setState(() { result = null; error = 'Confira os valores informados.'; });
    }
  }

  @override
  void dispose() {
    for (final c in [voltage, current, length, section, powerFactor, maxDrop]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Queda de Tensão')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Circuito', style: Theme.of(context).textTheme.titleLarge),
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
          Row(children: [
            Expanded(child: _field(voltage, 'Tensão (V)')),
            const SizedBox(width: 12),
            Expanded(child: _field(current, 'Corrente (A)')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(length, 'Comprimento (m)')),
            const SizedBox(width: 12),
            Expanded(child: _field(section, 'Seção (mm²)')),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<ConductorMaterial>(
            initialValue: material,
            decoration: const InputDecoration(labelText: 'Condutor'),
            items: const [
              DropdownMenuItem(value: ConductorMaterial.copper, child: Text('Cobre')),
              DropdownMenuItem(value: ConductorMaterial.aluminum, child: Text('Alumínio')),
            ],
            onChanged: (v) => setState(() => material = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(powerFactor, 'Fator de potência')),
            const SizedBox(width: 12),
            Expanded(child: _field(maxDrop, 'Limite (%)')),
          ]),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('CALCULAR'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (result != null) ...[
            const SizedBox(height: 20),
            Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(child: ListTile(
              leading: Icon(result!.withinLimit ? Icons.check_circle : Icons.warning_amber),
              title: Text(result!.withinLimit ? 'DENTRO DO LIMITE INFORMADO' : 'ACIMA DO LIMITE INFORMADO'),
            )),
            _result('Queda de tensão', result!.dropV, 'V'),
            _result('Queda percentual', result!.dropPercent, '%'),
            _result('Seção mínima pelo critério de queda', result!.minimumSectionMm2, 'mm²'),
            _result('Próxima seção comercial', result!.commercialSectionMm2, 'mm²'),
            const SizedBox(height: 12),
            const Text(
              'A seção indicada considera somente o critério matemático de queda de tensão. '
              'O dimensionamento final do condutor também deve verificar capacidade de condução, '
              'método de instalação, temperatura, agrupamento, proteção e demais critérios aplicáveis.',
            ),
          ],
        ],
      ),
    ),
  );

  Widget _field(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );

  Widget _result(String label, double value, String unit) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text('${value.toStringAsFixed(2)} $unit', style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
