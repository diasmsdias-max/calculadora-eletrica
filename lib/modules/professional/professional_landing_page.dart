import 'package:flutter/material.dart';

import '../../core/licensing/license_provider.dart';
import '../../core/licensing/license_state.dart';

class ProfessionalLandingPage extends StatefulWidget {
  const ProfessionalLandingPage({super.key});

  @override
  State<ProfessionalLandingPage> createState() =>
      _ProfessionalLandingPageState();
}

class _ProfessionalLandingPageState extends State<ProfessionalLandingPage> {
  final LicenseProvider _licenseProvider = const FreeLicenseProvider();
  LicenseState? _license;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final license = await _licenseProvider.currentState();
    if (mounted) setState(() => _license = license);
  }

  @override
  Widget build(BuildContext context) {
    final license = _license;
    return Scaffold(
      appBar: AppBar(title: const Text('VIS ELECTRICA Profissional')),
      body: license == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  license.hasProfessional
                      ? Icons.workspace_premium
                      : Icons.lock_outline,
                  size: 52,
                ),
                const SizedBox(height: 16),
                Text(
                  license.hasProfessional
                      ? 'Módulo Profissional ativo'
                      : 'Projeto elétrico completo em campo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Transforme o levantamento em um projeto organizado, '
                  'reaproveitando os cálculos técnicos do VIS ELECTRICA.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const _FlowStep(
                  icon: Icons.playlist_add_check,
                  title: 'Levantamento e Cargas',
                  text: 'Cadastre as cargas da instalação e vincule-as ao projeto do cliente.',
                ),
                const _FlowStep(
                  icon: Icons.account_tree_outlined,
                  title: 'Circuitos',
                  text: 'Agrupe as cargas e dimensione os circuitos sem redigitar informações.',
                ),
                const _FlowStep(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Quadros',
                  text: 'Organize circuitos, alimentação e distribuição por quadro.',
                ),
                const _FlowStep(
                  icon: Icons.shield_outlined,
                  title: 'Proteções',
                  text: 'Associe e verifique as proteções dos circuitos e do quadro.',
                ),
                const _FlowStep(
                  icon: Icons.inventory_2_outlined,
                  title: 'Materiais e PDF',
                  text: 'Consolide materiais e gere o relatório profissional do projeto.',
                ),
                const SizedBox(height: 16),
                if (!license.hasProfessional) ...[
                  FilledButton.icon(
                    onPressed: () => _showActivationInfo(context),
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Ativar módulo Profissional'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Os módulos gratuitos continuam disponíveis sem ativação.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
    );
  }

  void _showActivationInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativação Profissional'),
        content: const Text(
          'A infraestrutura de licença está preparada. O canal definitivo '
          'de contratação e ativação será conectado em uma etapa posterior, '
          'sem alterar os módulos gratuitos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FlowStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(text),
        ),
      );
}
