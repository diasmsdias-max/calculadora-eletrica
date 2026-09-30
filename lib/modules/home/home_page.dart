import 'package:flutter/material.dart';

import '../../core/settings/module_preferences.dart';
import '../cable_sizing/cable_sizing_page.dart';
import '../load_survey/load_survey_page.dart';
import '../motor/motor_page.dart';
import '../motor_transformer/motor_transformer_page.dart';
import '../projects/projects_page.dart';
import '../settings/settings_page.dart';
import '../transformer/transformer_page.dart';
import '../voltage_drop/voltage_drop_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Set<String>? _visible;

  static const modules = <_Module>[
    _Module('motor', 'Motor Elétrico', 'Dimensionamento e análise', Icons.electric_bolt),
    _Module('transformer', 'Transformador', 'Capacidade e carregamento', Icons.hub),
    _Module('motorTransformer', 'Motor × Transformador', 'Compatibilidade e margem', Icons.compare_arrows),
    _Module('loadSurvey', 'Levantamento de Cargas', 'Demanda, simultaneidade e consumo', Icons.playlist_add_check),
    _Module('cableSizing', 'Dimensionamento de Cabos', 'Seção e capacidade', Icons.cable),
    _Module('voltageDrop', 'Queda de Tensão', 'Queda em V e %', Icons.trending_down),
  ];

  @override
  void initState() {
    super.initState();
    _reloadPreferences();
  }

  Future<void> _reloadPreferences() async {
    final visible = await ModulePreferences.loadVisibleModules();
    if (mounted) setState(() => _visible = visible);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    await _reloadPreferences();
  }

  void _openModule(_Module module) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => switch (module.id) {
          'motor' => const MotorPage(),
          'transformer' => const TransformerPage(),
          'motorTransformer' => const MotorTransformerPage(),
          'loadSurvey' => const LoadSurveyPage(),
          'cableSizing' => const CableSizingPage(),
          'voltageDrop' => const VoltageDropPage(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleModules = _visible == null
        ? const <_Module>[]
        : modules.where((module) => _visible!.contains(module.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Elétrica'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _visible == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 720 ? 3 : 2;
                  final items = <Widget>[
                    ...visibleModules.map(
                      (module) => _ModuleCard(
                        module: module,
                        onTap: () => _openModule(module),
                      ),
                    ),
                    _ModuleCard(
                      module: const _Module(
                        'projects',
                        'Meus Projetos',
                        'Cálculos e relatórios salvos',
                        Icons.folder_outlined,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProjectsPage()),
                      ),
                    ),
                  ];

                  return GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 2 ? 1.05 : 1.35,
                    children: items,
                  );
                },
              ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(module.icon, size: 32),
                const SizedBox(height: 12),
                Text(module.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(module.subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _Module {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Module(this.id, this.title, this.subtitle, this.icon);
}
