import 'package:flutter/material.dart';
import '../../core/formatters/technical_format.dart';
import '../../core/calculations/conductor_check_calculator.dart';
import '../../core/calculations/power_calculator.dart';
import '../../core/calculations/voltage_drop_calculator.dart';
import '../../core/database/project_record.dart';
import '../../core/projects/project_record_saver.dart';

class CableSizingPage extends StatefulWidget {
  const CableSizingPage({super.key});
  @override
  State<CableSizingPage> createState() => _CableSizingPageState();
}

class _CableSizingPageState extends State<CableSizingPage> {
  final voltage = TextEditingController(text: '220');
  final current = TextEditingController(text: '40');
  final length = TextEditingController(text: '30');
  final section = TextEditingController(text: '6');
  final powerFactor = TextEditingController(text: '0,92');
  final maxDrop = TextEditingController(text: '4');
  final temperatureFactor = TextEditingController(text: '1,00');
  final groupingFactor = TextEditingController(text: '1,00');
  final referenceAmpacity = TextEditingController(text: '50');
  final reactance = TextEditingController(text: '0,10');

  AcSystem system = AcSystem.twoPhase;
  ConductorMaterial material = ConductorMaterial.copper;
  bool useEstimatedReactance = true;
  ConductorCheckResult? result;
  String? error;

  double _n(String v) => double.parse(v.trim().replaceAll(',', '.'));

  Future<void> _saveToProject() async {
    final r = result;
    if (r == null) return;
    await ProjectRecordSaver.save(
      context,
      type: ProjectRecordType.cableSizing,
      title: 'Condutor — ${TechnicalFormat.number(_n(section.text))} mm²',
      summary: '${TechnicalFormat.number(_n(current.text))} A | queda ${TechnicalFormat.number(r.voltageDrop.dropPercent)}% | ${r.meetsBothCriteria ? 'ATENDE' : 'NÃO ATENDE'}',
      data: {
        'system': system.name,
        'voltageV': _n(voltage.text),
        'designCurrentA': _n(current.text),
        'lengthM': _n(length.text),
        'sectionMm2': _n(section.text),
        'material': material.name,
        'powerFactor': _n(powerFactor.text),
        'maxDropPercent': _n(maxDrop.text),
        'reactanceOhmPerKm': _n(reactance.text),
        'reactanceSource': useEstimatedReactance ? 'practical_estimate' : 'custom',
        'temperatureFactor': _n(temperatureFactor.text),
        'groupingFactor': _n(groupingFactor.text),
        'referenceAmpacityA': _n(referenceAmpacity.text),
        'combinedCorrectionFactor': r.ampacity.combinedCorrectionFactor,
        'requiredReferenceAmpacityA': r.ampacity.requiredAmpacityA,
        'correctedAmpacityA': r.correctedAmpacityA,
        'ampacityMeets': r.ampacityMeets,
        'dropV': r.voltageDrop.dropV,
        'dropPercent': r.voltageDrop.dropPercent,
        'voltageDropMeets': r.voltageDrop.withinLimit,
        'minimumSectionByDropMm2': r.voltageDrop.minimumSectionMm2,
        'meetsBothCriteria': r.meetsBothCriteria,
        'scope': 'ampacity_corrected_and_voltage_drop',
      },
    );
  }

  void _calculate() {
    try {
      final r = ConductorCheckCalculator.calculate(
        system: system,
        voltageV: _n(voltage.text),
        designCurrentA: _n(current.text),
        lengthM: _n(length.text),
        sectionMm2: _n(section.text),
        material: material,
        powerFactor: _n(powerFactor.text),
        maxDropPercent: _n(maxDrop.text),
        temperatureFactor: _n(temperatureFactor.text),
        groupingFactor: _n(groupingFactor.text),
        referenceAmpacityA: _n(referenceAmpacity.text),
        reactanceOhmPerKm: _n(reactance.text),
      );
      setState(() { result = r; error = null; });
    } catch (_) {
      setState(() { result = null; error = 'Confira os valores informados.'; });
    }
  }

  @override
  void dispose() {
    for (final c in [
      voltage, current, length, section, powerFactor, maxDrop,
      temperatureFactor, groupingFactor, referenceAmpacity, reactance,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dimensionamento de Cabos')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          Text('Dados do circuito', style: Theme.of(context).textTheme.titleLarge),
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
            Expanded(child: _field(current, 'Ib (A)')),
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
            decoration: const InputDecoration(labelText: 'Material'),
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
            Expanded(child: _field(maxDrop, 'Limite queda (%)')),
          ]),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Estimativa rápida')),
              ButtonSegment(value: false, label: Text('Personalizado')),
            ],
            selected: {useEstimatedReactance},
            onSelectionChanged: (selection) => setState(() {
              useEstimatedReactance = selection.first;
              if (useEstimatedReactance) reactance.text = '0,10';
            }),
          ),
          const SizedBox(height: 8),
          _field(
            reactance,
            useEstimatedReactance
                ? 'Reatância X (Ω/km) — estimativa'
                : 'Reatância X (Ω/km) — personalizado',
          ),
          const SizedBox(height: 6),
          Text(
            useEstimatedReactance
                ? 'Estimativa prática: X = 0,10 Ω/km. Referência preliminar para cálculo rápido em campo.'
                : 'Informe a reatância conforme os dados do cabo ou da instalação.',
          ),
          const SizedBox(height: 20),
          Text('Capacidade de condução', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Informe os fatores e a ampacidade de referência conforme a tabela e o método de instalação aplicáveis.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(temperatureFactor, 'Fator temperatura')),
            const SizedBox(width: 12),
            Expanded(child: _field(groupingFactor, 'Fator agrupamento')),
          ]),
          const SizedBox(height: 12),
          _field(referenceAmpacity, 'Ampacidade de referência (A)'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.electrical_services),
            label: const Text('VERIFICAR CONDUTOR'),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (result != null) ...[
            const SizedBox(height: 20),
            Text('Resultado integrado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(child: ListTile(
              leading: Icon(result!.meetsBothCriteria ? Icons.check_circle : Icons.warning_amber),
              title: Text(result!.meetsBothCriteria
                  ? 'ATENDE AOS DOIS CRITÉRIOS'
                  : 'NÃO ATENDE AOS DOIS CRITÉRIOS'),
            )),
            _status('Capacidade de corrente', result!.ampacityMeets),
            _result('Iz mínima de referência', result!.ampacity.requiredAmpacityA, 'A'),
            _result('Iz corrigida do cabo', result!.correctedAmpacityA, 'A'),
            _status('Queda de tensão', result!.voltageDrop.withinLimit),
            _result('Queda', result!.voltageDrop.dropV, 'V'),
            _result('Queda percentual', result!.voltageDrop.dropPercent, '%'),
            _result('Seção mínima pelo critério de queda', result!.voltageDrop.minimumSectionMm2, 'mm²'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saveToProject,
              icon: const Icon(Icons.save_outlined),
              label: const Text('SALVAR NO PROJETO'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Resultado técnico parcial: a aprovação acima confirma somente capacidade de corrente corrigida '
              'e queda de tensão. O dimensionamento final ainda deve considerar seção mínima aplicável, '
              'proteção, curto-circuito e demais requisitos do circuito.',
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

  Widget _status(String label, bool ok) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(ok ? 'ATENDE' : 'NÃO ATENDE',
        style: TextStyle(color: ok ? Colors.greenAccent : Theme.of(context).colorScheme.error)),
    ),
  );

  Widget _result(String label, double value, String unit) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text('${TechnicalFormat.number(value)} $unit',
        style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
