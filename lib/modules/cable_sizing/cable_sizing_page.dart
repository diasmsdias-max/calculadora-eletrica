import 'package:flutter/material.dart';
import '../../core/calculations/cable_sizing_calculator.dart';

class CableSizingPage extends StatefulWidget {
  const CableSizingPage({super.key});
  @override
  State<CableSizingPage> createState() => _CableSizingPageState();
}

class _CableSizingPageState extends State<CableSizingPage> {
  final designCurrent = TextEditingController(text: '40');
  final temperatureFactor = TextEditingController(text: '1,00');
  final groupingFactor = TextEditingController(text: '1,00');
  final referenceAmpacity = TextEditingController(text: '50');

  CableSizingResult? result;
  double? correctedAmpacity;
  bool? meets;
  String? error;

  double _n(String v) => double.parse(v.trim().replaceAll(',', '.'));

  void _calculate() {
    try {
      final r = CableSizingCalculator.calculate(
        designCurrentA: _n(designCurrent.text),
        temperatureFactor: _n(temperatureFactor.text),
        groupingFactor: _n(groupingFactor.text),
      );
      final reference = _n(referenceAmpacity.text);
      if (!reference.isFinite || reference <= 0) {
        throw ArgumentError();
      }
      setState(() {
        result = r;
        correctedAmpacity = r.correctedAmpacity(reference);
        meets = r.cableMeets(reference);
        error = null;
      });
    } catch (_) {
      setState(() {
        result = null;
        correctedAmpacity = null;
        meets = null;
        error = 'Confira os valores informados.';
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      designCurrent,
      temperatureFactor,
      groupingFactor,
      referenceAmpacity,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text('Capacidade de condução',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Etapa de verificação por corrente. Informe a ampacidade de '
                'referência do condutor conforme a tabela e o método de instalação aplicáveis.',
              ),
              const SizedBox(height: 16),
              _field(designCurrent, 'Corrente de projeto — Ib (A)'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field(
                        temperatureFactor, 'Fator temperatura')),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(groupingFactor, 'Fator agrupamento')),
              ]),
              const SizedBox(height: 12),
              _field(referenceAmpacity, 'Ampacidade de referência do cabo (A)'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.electrical_services),
                label: const Text('VERIFICAR CABO'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              if (result != null) ...[
                const SizedBox(height: 20),
                Text('Resultado',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(meets!
                        ? Icons.check_circle
                        : Icons.warning_amber),
                    title: Text(meets!
                        ? 'CAPACIDADE DE CORRENTE ATENDE'
                        : 'CAPACIDADE DE CORRENTE NÃO ATENDE'),
                  ),
                ),
                _result('Fator de correção combinado',
                    result!.combinedCorrectionFactor, ''),
                _result('Iz mínima de referência necessária',
                    result!.requiredAmpacityA, 'A'),
                _result('Iz corrigida do cabo informado',
                    correctedAmpacity!, 'A'),
                const SizedBox(height: 12),
                const Text(
                  'Esta verificação não seleciona automaticamente a seção e '
                  'não substitui os demais critérios de dimensionamento. '
                  'A seção final também deve atender queda de tensão, seção mínima, '
                  'proteção, curto-circuito e demais requisitos aplicáveis.',
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
          trailing: Text(
            '${value.toStringAsFixed(2)}$unit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
}
