import 'package:flutter/material.dart';

import '../../core/settings/module_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Set<String>? _visible;

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
    final visible = await ModulePreferences.loadVisibleModules();
    if (mounted) setState(() => _visible = visible);
  }

  Future<void> _setVisible(String id, bool value) async {
    final next = Set<String>.from(_visible ?? {});
    value ? next.add(id) : next.remove(id);
    setState(() => _visible = next);
    await ModulePreferences.saveVisibleModules(next);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: _visible == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Text('Módulos da tela inicial',
                      style: Theme.of(context).textTheme.titleLarge),
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
