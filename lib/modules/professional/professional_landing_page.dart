import 'package:flutter/material.dart';

import '../../core/licensing/license_provider.dart';
import '../../core/licensing/license_provider_factory.dart';
import '../../core/licensing/license_state.dart';
import '../../core/licensing/vis_license_api.dart';
import '../../core/licensing/vis_license_provider.dart';
import '../../core/database/v2_persistence_factory.dart';
import '../../core/technical_center/technical_center_config.dart';
import '../../core/technical_center/technical_center_runtime.dart';
import 'professional_profile_page.dart';
import 'professional_projects_page.dart';
import 'technical_center_page.dart';

class ProfessionalLandingPage extends StatefulWidget {
  const ProfessionalLandingPage({super.key});

  @override
  State<ProfessionalLandingPage> createState() =>
      _ProfessionalLandingPageState();
}

class _ProfessionalLandingPageState extends State<ProfessionalLandingPage> {
  final LicenseProvider _licenseProvider = LicenseProviderFactory.create();
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
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfessionalProjectsPage(license: license),
                    ),
                  ),
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Projetos Elétricos'),
                ),
                const SizedBox(height: 8),
                if (license.hasProfessional)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final persistence = await V2PersistenceFactory.defaults().initialize();
                      if (!context.mounted) return;
                      final baseUri = TechnicalCenterConfig.baseUri;
                      final runtime = baseUri == null
                          ? null
                          : await TechnicalCenterRuntime.create(
                              repository: persistence.technicalDocuments,
                              baseUri: baseUri,
                            );
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TechnicalCenterPage(
                            repository: persistence.technicalDocuments,
                            actions: runtime,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Central Técnica VIS'),
                  ),
                const SizedBox(height: 8),
                if (!license.hasProfessional)
                  const Text(
                    'Projetos existentes permanecem acessíveis em modo de leitura.',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                if (license.hasProfessional)
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfessionalProfilePage(),
                      ),
                    ),
                    icon: const Icon(Icons.business_outlined),
                    label: const Text('Configurar Perfil Profissional'),
                  ),
                if (!license.hasProfessional) ...[
                  FilledButton.icon(
                    onPressed: _activate,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Ativar VIS ELECTRICA Profissional'),
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

  Future<void> _activate() async {
    if (_licenseProvider is! VisLicenseProvider) {
      _showActivationInfo(context);
      return;
    }
    final controller = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativar VIS ELECTRICA Profissional'),
        content: TextField(
          controller: controller,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Chave de ativação',
            hintText: 'VIS-PRO-XXXX-XXXX-XXXX-XXXX-XXXX',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ATIVAR'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (key == null || key.isEmpty) return;
    try {
      final license = await _licenseProvider.activate(key);
      if (!mounted) return;
      setState(() => _license = license);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(license.hasProfessional
            ? 'VIS ELECTRICA Profissional ativado.'
            : 'A licença não liberou o módulo Profissional.'),
      ));
    } on VisLicenseApiException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'INVALID_ACTIVATION_KEY' => 'Chave de ativação inválida.',
        'LICENSE_INACTIVE' => 'Esta licença está inativa.',
        'LICENSE_EXPIRED' => 'Esta licença está expirada.',
        'DEVICE_LIMIT_REACHED' => 'Limite de dispositivos atingido.',
        _ => 'Não foi possível concluir a ativação. Verifique a conexão e tente novamente.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível concluir a ativação. Verifique a conexão e tente novamente.'),
      ));
    }
  }

  void _showActivationInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativação Profissional'),
        content: const Text(
          'O licenciamento deste build ainda não está configurado. '
          'Os módulos gratuitos continuam disponíveis normalmente.',
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
