import 'package:flutter/material.dart';
import '../../core/formatters/technical_format.dart';
import '../../core/calculations/motor_calculator.dart';
import '../../core/calculations/power_calculator.dart';
import '../../core/database/local_project.dart';
import '../../core/database/project_record.dart';
import '../../core/database/project_record_repository.dart';
import '../../core/database/project_repository.dart';

class MotorPage extends StatefulWidget {
  const MotorPage({super.key});
  @override
  State<MotorPage> createState() => _MotorPageState();
}

class _MotorPageState extends State<MotorPage> {
  final power = TextEditingController(text: '15');
  final current = TextEditingController(text: '40');
  final voltage = TextEditingController(text: '220');
  final pf = TextEditingController(text: '0,85');
  final efficiency = TextEditingController(text: '0,90');
  final serviceFactor = TextEditingController(text: '1,00');
  final hours = TextEditingController(text: '8');
  final days = TextEditingController(text: '30');
  final startingMultiplier = TextEditingController(text: '6,0');

  MotorInputMode inputMode = MotorInputMode.power;
  MotorPowerUnit unit = MotorPowerUnit.cv;
  AcSystem system = AcSystem.threePhase;
  MotorStartingMethod startingMethod = MotorStartingMethod.direct;
  MotorResult? result;
  String? error;

  double _n(String value) => double.parse(value.trim().replaceAll(',', '.'));

  void _methodChanged(MotorStartingMethod value) {
    setState(() {
      startingMethod = value;
      startingMultiplier.text =
          MotorCalculator.suggestedStartingMultiplier(value).toStringAsFixed(1).replaceAll('.', ',');
    });
  }

  Future<void> _saveToProject() async {
    final r = result;
    if (r == null) return;
    final projects = await PreferencesProjectRepository().getAll();
    if (!mounted) return;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie um projeto em Meus Projetos antes de salvar o cálculo.')),
      );
      return;
    }
    final selected = await showDialog<LocalProject>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Salvar em qual projeto?'),
        children: projects.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(p.client.isEmpty ? p.name : '${p.name}\n${p.client}'),
          ),
        )).toList(),
      ),
    );
    if (selected == null) return;
    final now = DateTime.now();
    final inputValue = inputMode == MotorInputMode.power ? _n(power.text) : _n(current.text);
    final inputLabel = inputMode == MotorInputMode.power
        ? '${TechnicalFormat.number(inputValue)} ${unit.name.toUpperCase()}'
        : '${TechnicalFormat.number(inputValue)} A';
    final record = ProjectRecord(
      id: now.microsecondsSinceEpoch.toString(),
      projectId: selected.id,
      type: ProjectRecordType.motor,
      title: 'Motor — $inputLabel',
      summary: '${TechnicalFormat.number(r.nominalCurrentA)} A | ${TechnicalFormat.number(r.apparentPowerKva)} kVA',
      createdAt: now,
      data: {
        'inputMode': inputMode.name,
        'ratedPower': inputMode == MotorInputMode.power ? _n(power.text) : null,
        'powerUnit': unit.name,
        'informedCurrentA': inputMode == MotorInputMode.current ? _n(current.text) : null,
        'system': system.name,
        'voltageV': _n(voltage.text),
        'powerFactor': _n(pf.text),
        'efficiency': _n(efficiency.text),
        'serviceFactor': _n(serviceFactor.text),
        'startingMethod': startingMethod.name,
        'startingMultiplier': _n(startingMultiplier.text),
        'hoursPerDay': _n(hours.text),
        'daysPerMonth': int.parse(days.text),
        'shaftPowerKw': r.shaftPowerKw,
        'servicePowerKw': r.servicePowerKw,
        'absorbedPowerKw': r.absorbedPowerKw,
        'apparentPowerKva': r.apparentPowerKva,
        'nominalCurrentA': r.nominalCurrentA,
        'estimatedStartingCurrentA': r.estimatedStartingCurrentA,
        'dailyEnergyKwh': r.dailyEnergyKwh,
        'monthlyEnergyKwh': r.monthlyEnergyKwh,
      },
    );
    await PreferencesProjectRecordRepository().save(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cálculo salvo em “${selected.name}”.')),
    );
  }

  void _calculate() {
    try {
      final common = (
        system: system,
        voltageV: _n(voltage.text),
        powerFactor: _n(pf.text),
        efficiency: _n(efficiency.text),
        serviceFactor: _n(serviceFactor.text),
        hoursPerDay: _n(hours.text),
        daysPerMonth: int.parse(days.text),
        startingMethod: startingMethod,
        startingMultiplier: _n(startingMultiplier.text),
      );
      final value = inputMode == MotorInputMode.power
          ? MotorCalculator.calculate(
              ratedPower: _n(power.text), unit: unit, system: common.system,
              voltageV: common.voltageV, powerFactor: common.powerFactor,
              efficiency: common.efficiency, serviceFactor: common.serviceFactor,
              hoursPerDay: common.hoursPerDay, daysPerMonth: common.daysPerMonth,
              startingMethod: common.startingMethod, startingMultiplier: common.startingMultiplier,
            )
          : MotorCalculator.calculateFromCurrent(
              currentA: _n(current.text), system: common.system,
              voltageV: common.voltageV, powerFactor: common.powerFactor,
              efficiency: common.efficiency, serviceFactor: common.serviceFactor,
              hoursPerDay: common.hoursPerDay, daysPerMonth: common.daysPerMonth,
              startingMethod: common.startingMethod, startingMultiplier: common.startingMultiplier,
            );
      setState(() { result = value; error = null; });
    } catch (_) {
      setState(() { result = null; error = 'Confira os valores informados.'; });
    }
  }

  @override
  void dispose() {
    for (final c in [power, current, voltage, pf, efficiency, serviceFactor, hours, days, startingMultiplier]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Motor Elétrico')),
    body: SafeArea(top: false, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      Text('Dados do motor', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      SegmentedButton<MotorInputMode>(
        segments: const [
          ButtonSegment(value: MotorInputMode.power, label: Text('Por potência'), icon: Icon(Icons.bolt)),
          ButtonSegment(value: MotorInputMode.current, label: Text('Por corrente'), icon: Icon(Icons.electric_meter)),
        ],
        selected: {inputMode},
        onSelectionChanged: (v) => setState(() { inputMode = v.first; result = null; }),
      ),
      const SizedBox(height: 12),
      if (inputMode == MotorInputMode.power)
        Row(children: [
          Expanded(child: _field(power, 'Potência nominal')),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<MotorPowerUnit>(
            initialValue: unit, decoration: const InputDecoration(labelText: 'Unidade'),
            items: const [
              DropdownMenuItem(value: MotorPowerUnit.cv, child: Text('CV')),
              DropdownMenuItem(value: MotorPowerUnit.hp, child: Text('HP')),
              DropdownMenuItem(value: MotorPowerUnit.kw, child: Text('kW')),
            ], onChanged: (v) => setState(() => unit = v!),
          )),
        ])
      else
        _field(current, 'Corrente nominal (A)'),
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
      _field(serviceFactor, 'Fator de serviço'),
      const SizedBox(height: 20),
      Text('Operação e partida', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      DropdownButtonFormField<MotorStartingMethod>(
        initialValue: startingMethod, decoration: const InputDecoration(labelText: 'Método de partida'),
        items: MotorStartingMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
        onChanged: (v) => _methodChanged(v!),
      ),
      const SizedBox(height: 12),
      _field(startingMultiplier, 'Multiplicador estimado de partida (× In)'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _field(hours, 'Horas/dia')),
        const SizedBox(width: 12),
        Expanded(child: _field(days, 'Dias/mês', decimal: false)),
      ]),
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate), label: const Text('CALCULAR')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (result != null) ...[
        const SizedBox(height: 20),
        Text('Resultado', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _result('Potência mecânica nominal', result!.shaftPowerKw, 'kW'),
        _result('Potência com fator de serviço', result!.servicePowerKw, 'kW'),
        _result('Potência elétrica absorvida', result!.absorbedPowerKw, 'kW'),
        _result('Potência aparente', result!.apparentPowerKva, 'kVA'),
        _result(inputMode == MotorInputMode.power ? 'Corrente nominal calculada' : 'Corrente nominal informada', result!.nominalCurrentA, 'A'),
        _result('Corrente de partida estimada', result!.estimatedStartingCurrentA, 'A'),
        _result('Consumo diário estimado', result!.dailyEnergyKwh, 'kWh'),
        _result('Consumo mensal estimado', result!.monthlyEnergyKwh, 'kWh'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saveToProject,
          icon: const Icon(Icons.save_outlined),
          label: const Text('SALVAR NO PROJETO'),
        ),
        const SizedBox(height: 12),
        const Text('Consumo estimado considerando operação à carga nominal. A corrente de partida é uma estimativa baseada no multiplicador informado. Use Ip/In de placa ou dados do fabricante quando disponíveis.'),
      ],
    ])),
  );

  Widget _field(TextEditingController controller, String label, {bool decimal = true}) =>
    TextField(controller: controller, keyboardType: TextInputType.numberWithOptions(decimal: decimal), decoration: InputDecoration(labelText: label));

  Widget _result(String label, double value, String u) => Card(
    child: ListTile(title: Text(label), trailing: Text('${TechnicalFormat.number(value)} $u', style: Theme.of(context).textTheme.titleMedium)),
  );
}
