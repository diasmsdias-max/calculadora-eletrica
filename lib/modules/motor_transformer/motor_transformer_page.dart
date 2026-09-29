import 'package:flutter/material.dart';
import '../../core/calculations/motor_calculator.dart';
import '../../core/calculations/motor_transformer_calculator.dart';
import '../../core/calculations/power_calculator.dart';

class MotorTransformerPage extends StatefulWidget {
  const MotorTransformerPage({super.key});
  @override
  State<MotorTransformerPage> createState() => _MotorTransformerPageState();
}

class _MotorTransformerPageState extends State<MotorTransformerPage> {
  final transformerKva = TextEditingController(text: '10');
  final motorPower = TextEditingController(text: '15');
  final voltage = TextEditingController(text: '220');
  final pf = TextEditingController(text: '0,85');
  final efficiency = TextEditingController(text: '0,90');
  final startingMultiplier = TextEditingController(text: '6,0');

  MotorPowerUnit unit = MotorPowerUnit.cv;
  AcSystem system = AcSystem.threePhase;
  MotorStartingMethod startingMethod = MotorStartingMethod.direct;
  MotorTransformerResult? result;
  String? error;

  double _n(String v) => double.parse(v.trim().replaceAll(',', '.'));

  void _methodChanged(MotorStartingMethod value) {
    setState(() {
      startingMethod = value;
      startingMultiplier.text = MotorCalculator.suggestedStartingMultiplier(value)
          .toStringAsFixed(1).replaceAll('.', ',');
    });
  }

  void _calculate() {
    try {
      final value = MotorTransformerCalculator.calculate(
        transformerKva: _n(transformerKva.text),
        motorRatedPower: _n(motorPower.text),
        motorUnit: unit,
        system: system,
        voltageV: _n(voltage.text),
        powerFactor: _n(pf.text),
        efficiency: _n(efficiency.text),
        startingMethod: startingMethod,
        startingMultiplier: _n(startingMultiplier.text),
      );
      setState(() { result = value; error = null; });
    } catch (_) {
      setState(() { result = null; error = 'Confira os valores informados.'; });
    }
  }

  @override
  void dispose() {
    for (final c in [transformerKva, motorPower, voltage, pf, efficiency, startingMultiplier]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Motor × Transformador')),
    body: SafeArea(top: false, child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Transformador', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _field(transformerKva, 'Potência do transformador (kVA)'),
        const SizedBox(height: 20),
        Text('Motor', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(motorPower, 'Potência nominal')),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<MotorPowerUnit>(
            initialValue: unit, decoration: const InputDecoration(labelText: 'Unidade'),
            items: const [
              DropdownMenuItem(value: MotorPowerUnit.cv, child: Text('CV')),
              DropdownMenuItem(value: MotorPowerUnit.hp, child: Text('HP')),
              DropdownMenuItem(value: MotorPowerUnit.kw, child: Text('kW')),
            ], onChanged: (v) => setState(() => unit = v!),
          )),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<AcSystem>(
          initialValue: system, decoration: const InputDecoration(labelText: 'Sistema'),
          items: const [
            DropdownMenuItem(value: AcSystem.singlePhase, child: Text('Monofásico')),
            DropdownMenuItem(value: AcSystem.twoPhase, child: Text('Bifásico')),
            DropdownMenuItem(value: AcSystem.threePhase, child: Text('Trifásico')),
          ], onChanged: (v) => setState(() => system = v!),
        ),
        const SizedBox(height: 12),
        _field(voltage, 'Tensão (V)'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field(pf, 'Fator de potência')),
          const SizedBox(width: 12),
          Expanded(child: _field(efficiency, 'Rendimento')),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<MotorStartingMethod>(
          initialValue: startingMethod,
          decoration: const InputDecoration(labelText: 'Método de partida'),
          items: MotorStartingMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
          onChanged: (v) => _methodChanged(v!),
        ),
        const SizedBox(height: 12),
        _field(startingMultiplier, 'Multiplicador estimado de partida (× In)'),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('ANALISAR')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (result != null) ...[
          const SizedBox(height: 20),
          Text('Regime permanente', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: Icon(result!.transformer.meetsLoad ? Icons.check_circle : Icons.warning_amber),
            title: Text(result!.transformer.meetsLoad ? 'ATENDE EM REGIME PERMANENTE' : 'NÃO ATENDE EM REGIME PERMANENTE'),
          )),
          const SizedBox(height: 8),
          _result('Motor', result!.motor.apparentPowerKva, 'kVA'),
          _result('Corrente nominal do motor', result!.motor.nominalCurrentA, 'A'),
          _result('Transformador ocupado', result!.motorTransformerPercent, '%'),
          _result('Capacidade restante', result!.transformer.remainingKva, 'kVA'),
          const SizedBox(height: 20),
          Text('Partida estimada', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _result('Corrente de partida', result!.motor.estimatedStartingCurrentA, 'A'),
          _result('Demanda aparente na partida', result!.startingKvaEstimate, 'kVA'),
          _result('Relação com a potência do trafo', result!.startingTransformerPercent, '%'),
          const SizedBox(height: 12),
          const Text('A seção de partida é uma estimativa baseada no multiplicador Ip/In. Ela não confirma, isoladamente, que o transformador suportará a partida. A avaliação completa deve considerar impedância do transformador, queda de tensão admissível, rede a montante, método de partida e dados do fabricante.'),
        ],
      ],
    )),
  );

  Widget _field(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );

  Widget _result(String label, double value, String unit) => Card(
    child: ListTile(title: Text(label), trailing: Text('${value.toStringAsFixed(2)} $unit', style: Theme.of(context).textTheme.titleMedium)),
  );
}
