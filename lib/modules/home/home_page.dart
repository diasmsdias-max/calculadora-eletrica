import 'package:flutter/material.dart';
import '../shared/module_placeholder_page.dart';
import '../motor/motor_page.dart';
import '../transformer/transformer_page.dart';
import '../motor_transformer/motor_transformer_page.dart';
import '../load_survey/load_survey_page.dart';
import '../voltage_drop/voltage_drop_page.dart';
import '../cable_sizing/cable_sizing_page.dart';
import '../projects/projects_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const modules = <_Module>[
    _Module('Motor Elétrico', 'Dimensionamento e análise', Icons.electric_bolt),
    _Module('Transformador', 'Capacidade e carregamento', Icons.hub),
    _Module('Motor × Transformador', 'Compatibilidade e margem', Icons.compare_arrows),
    _Module('Levantamento de Cargas', 'Demanda, simultaneidade e consumo', Icons.playlist_add_check),
    _Module('Dimensionamento de Cabos', 'Seção e capacidade', Icons.cable),
    _Module('Queda de Tensão', 'Queda em V e %', Icons.trending_down),
    _Module('Meus Projetos', 'Cálculos e relatórios salvos', Icons.folder_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora Elétrica')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 2 ? 1.05 : 1.35,
              ),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => switch (index) {
                          0 => const MotorPage(),
                          1 => const TransformerPage(),
                          2 => const MotorTransformerPage(),
                          3 => const LoadSurveyPage(),
                          4 => const CableSizingPage(),
                          5 => const VoltageDropPage(),
                          6 => const ProjectsPage(),
                          _ => ModulePlaceholderPage(
                              title: module.title,
                              subtitle: module.subtitle,
                              icon: module.icon,
                            ),
                        },
                      ),
                    ),
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
              },
            );
          },
        ),
      ),
    );
  }
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Module(this.title, this.subtitle, this.icon);
}
