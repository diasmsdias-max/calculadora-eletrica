import 'package:flutter/material.dart';
import '../../core/calculations/motor_calculator.dart';
import '../../core/calculations/power_calculator.dart';

class MotorPage extends StatefulWidget {
  const MotorPage({super.key});

  @override
  State<MotorPage> createState() => _MotorPageState();
}

class _MotorPageState extends State<MotorPage> {
  final power = TextEditingController(text: '15');
  final voltage = TextEditingController(text: '220');
  final pf = TextEditingController(text: '0,85');
  final efficiency = TextEditingController(text: '0,90');
  MotorPowerUnit unit = MotorPowerUnit.cv;
  AcSystem system = AcSystem.threePhase;
  MotorResult? result;
  String? error;

  double _number(String value) => double.parse(value.trim().replaceAll(',', '.'));

  void _calculate() {
    try {
      final value = MotorCalculator.calculate(
        ratedPower: _number(power.text),
        unit: unit,
        system: system,
        voltageV: _number(voltage.text),
        powerFactor: _number(pf.text),
        efficiency: _number(efficiency.text),
      );
      setState(() { result = value; error = null; });
    } catch (_) {
      setState(() { result = null; error = 'Confira os valores informados.'; });
    }
  }

  @override
  void dispose() {
    power.dispose(); voltage.dispose(); pf.dispose(); efficiency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motor Elétrico')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Dados do motor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _field(power, 'Potência nominal', decimal: true)),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<MotorPowerUnit>(
              initialValue: unit,
              decoration: const InputDecoration(labelText: 'Unidade'),
              items: const [
                DropdownMenuItem(value: MotorPowerUnit.cv, child: Text('CV')),
                DropdownMenuItem(value: MotorPowerUnit.hp, child: Text('HP')),
                DropdownMenuItem(value: MotorPowerUnit.kw, child: Text('kW')),
              ],
              onChanged: (v) => setState(() => unit = v!),
            )),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<AcSystem>(
            initialValue: system,
            decoration: const InputDecoration(labelText: 'Sistema'),
            items: const [
              DropdownMenuItem(value: AcSystem.singlePhase, child: Text('Monofásico')),
              DropdownMenuItem(value: AcSystem.threePhase, child: Text('Trifásico')),
            ],
            onChanged: (v) => setState(() => system = v!),
          ),
          const SizedBox(height: 12),
          _field(voltage, 'Tensão (V)', decimal: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(pf, 'Fator de potência', decimal: true)),
            const SizedBox(width: 12),
            Expanded(child: _field(efficiency, 'Rendimento', decimal: true)),
          ]),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('CALCULAR'),
          ),
          if (error != null) Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _result('Potência mecânica', result!.shaftPowerKw, 'kW'),
            _result('Potência absorvida', result!.absorbedPowerKw, 'kW'),
            _result('Potência aparente', result!.apparentPowerKva, 'kVA'),
            _result('Corrente nominal calculada', result!.nominalCurrentA, 'A'),
            const SizedBox(height: 12),
            const Text('Resultado calculado a partir dos dados informados. Para seleção de proteção, cabos e partida, serão aplicados critérios específicos nos módulos correspondentes.'),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool decimal = false}) =>
      TextField(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: decimal), decoration: InputDecoration(labelText: label));

  Widget _result(String label, double value, String unitLabel) => Card(
    child: ListTile(title: Text(label), trailing: Text('${value.toStringAsFixed(2)} $unitLabel', style: Theme.of(context).textTheme.titleMedium)),
  );
}
