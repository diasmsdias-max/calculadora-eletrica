import 'package:flutter/material.dart';

import '../../core/licensing/license_provider.dart';
import '../../core/licensing/license_state.dart';
import '../../core/professional/professional_profile.dart';
import '../../core/professional/professional_profile_repository.dart';
import '../../core/settings/module_preferences.dart';
import '../../core/settings/professional_module_preferences.dart';
import '../professional/professional_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LicenseProvider _licenseProvider = const FreeLicenseProvider();
  final ProfessionalProfileRepository _profileRepository =
      LocalProfessionalProfileRepository();

  Set<String>? _visible;
  bool? _professionalVisible;
  LicenseState? _license;
  ProfessionalProfile? _profile;

  static const _modules = <(String, String, String)>[
    ('motor', 'Motor Elétrico', 'Dimensionamento e análise'),
    ('transformer', 'Transformador', 'Capacidade e carregamento'),
    ('motorTransformer', 'Motor × Transformador', 'Compatibilidade e margem'),
    ('loadSurvey', 'Levantamento de Cargas', 'Demanda, simultaneidade e consumo'),
    ('cableSizing', 'Dimensionamento de Cabos', 'Seção e capacidade'),
    ('voltageDrop', 'Queda de Tensão', 'Queda em V e %'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      ModulePreferences.loadVisibleModules(),
      ProfessionalModulePreferences.loadVisible(),
      _licenseProvider.currentState(),
      _profileRepository.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _visible = results[0] as Set<String>;
      _professionalVisible = results[1] as bool;
      _license = results[2] as LicenseState;
      _profile = results[3] as ProfessionalProfile?;
    });
  }

  Future<void> _setVisible(String id, bool value) async {
    final next = Set<String>.from(_visible ?? {});
    value ? next.add(id) : next.remove(id);
    setState(() => _visible = next);
    await ModulePreferences.saveVisibleModules(next);
  }

  Future<void> _setProfessionalVisible(bool value) async {
    setState(() => _professionalVisible = value);
    await ProfessionalModulePreferences.saveVisible(value);
  }

  Future<void> _openProfessionalProfile() async {
    final profile = await Navigator.of(context).push<ProfessionalProfile>(
      MaterialPageRoute(builder: (_) => const ProfessionalProfilePage()),
    );
    if (profile != null && mounted) {
      setState(() => _profile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _visible != null &&
        _professionalVisible != null &&
        _license != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  'Módulos da tela inicial',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escolha as ferramentas que deseja ver na tela principal. '
                  'Ocultar um módulo não apaga projetos nem cálculos salvos.',
                ),
                const SizedBox(height: 12),
                ..._modules.map(
                  (module) => SwitchListTile(
                    value: _visible!.contains(module.$1),
                    onChanged: (value) => _setVisible(module.$1, value),
                    title: Text(module.$2),
                    subtitle: Text(module.$3),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  value: _professionalVisible!,
                  onChanged: _setProfessionalVisible,
                  secondary: Icon(
                    _license!.hasProfessional
                        ? Icons.workspace_premium
                        : Icons.lock_outline,
                  ),
                  title: const Text('VIS ELECTRICA Profissional'),
                  subtitle: Text(
                    _license!.hasProfessional
                        ? 'Módulo Profissional ativado.'
                        : 'Projeto completo: cargas, circuitos, quadros, '
                            'proteções, materiais e PDF. Requer licença.',
                  ),
                ),
                if (_license!.hasProfessional) ...[
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: const Text('Perfil Profissional'),
                    subtitle: Text(
                      _profile?.isConfigured == true
                          ? _profile!.companyName
                          : 'Configure nome, CNPJ/CPF e telefone.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openProfessionalProfile,
                  ),
                ],
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.folder_outlined),
                  title: Text('Meus Projetos'),
                  subtitle: Text(
                    'Permanece sempre disponível para preservar acesso aos dados e relatórios.',
                  ),
                ),
              ],
            ),
    );
  }
}
