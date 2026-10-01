import 'package:flutter/material.dart';

import '../../core/licensing/license_state.dart';
import '../../core/professional/professional_project.dart';
import '../../core/professional/professional_project_repository.dart';
import '../../core/database/v2_persistence_factory.dart';
import 'professional_loads_page.dart';
import 'professional_circuits_page.dart';
import 'professional_boards_page.dart';
import 'professional_protections_page.dart';
import 'professional_sizing_page.dart';
import 'professional_project_form_page.dart';

class ProfessionalProjectDashboardPage extends StatefulWidget {
  final ProfessionalProjectRepository repository;
  final ProfessionalProject project;
  final LicenseState license;

  const ProfessionalProjectDashboardPage({
    super.key,
    required this.repository,
    required this.project,
    required this.license,
  });

  @override
  State<ProfessionalProjectDashboardPage> createState() =>
      _ProfessionalProjectDashboardPageState();
}

class _ProfessionalProjectDashboardPageState
    extends State<ProfessionalProjectDashboardPage> {
  late ProfessionalProject _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  Future<void> _editProject() async {
    final updated = await Navigator.of(context).push<ProfessionalProject>(
      MaterialPageRoute(
        builder: (_) => ProfessionalProjectFormPage(
          repository: widget.repository,
          project: _project,
          readOnly: !widget.license.canEditProfessionalProjects,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _project = updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(_project.name),
          actions: [
            IconButton(
              onPressed: _editProject,
              tooltip: widget.license.canEditProfessionalProjects
                  ? 'Editar dados do projeto'
                  : 'Ver dados do projeto',
              icon: Icon(
                widget.license.canEditProfessionalProjects
                    ? Icons.edit_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(_project.name),
                subtitle: Text([
                  if (_project.client.isNotEmpty) _project.client,
                  if (_project.address.isNotEmpty) _project.address,
                  'Revisão ${_project.revision}',
                ].join('\n')),
                onTap: _editProject,
              ),
            ),
            const SizedBox(height: 8),
            _ProjectSection(
              icon: Icons.electrical_services_outlined,
              title: 'Cargas',
              subtitle: 'Cargas levantadas e vinculadas ao projeto.',
              enabled: true,
              onTap: () async {
                final persistence = await V2PersistenceFactory.defaults().initialize();
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfessionalLoadsPage(
                      repository: persistence.professionalLoads,
                      projectId: _project.id,
                      readOnly: !widget.license.canEditProfessionalProjects,
                    ),
                  ),
                );
              },
            ),
            _ProjectSection(
              icon: Icons.account_tree_outlined,
              title: 'Circuitos',
              subtitle: 'Agrupamento, alimentação e dados dos circuitos.',
              enabled: true,
              onTap: () async {
                final persistence = await V2PersistenceFactory.defaults().initialize();
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfessionalCircuitsPage(
                      repository: persistence.professionalCircuits,
                      loadsRepository: persistence.professionalLoads,
                      projectId: _project.id,
                      readOnly: !widget.license.canEditProfessionalProjects,
                    ),
                  ),
                );
              },
            ),
            const _ProjectSection(
              icon: Icons.dashboard_customize_outlined,
              title: 'Quadros',
              subtitle: 'Quadros e distribuição dos circuitos.',
              enabled: false,
            ),
            const _ProjectSection(
              icon: Icons.shield_outlined,
              title: 'Proteções',
              subtitle: 'Proteções associadas a circuitos e quadros.',
              enabled: false,
            ),
            const _ProjectSection(
              icon: Icons.calculate_outlined,
              title: 'Dimensionamento',
              subtitle: 'Critérios e resultados técnicos do projeto.',
              enabled: false,
            ),
            const _ProjectSection(
              icon: Icons.inventory_2_outlined,
              title: 'Materiais',
              subtitle: 'Lista consolidada de materiais.',
              enabled: false,
            ),
            const _ProjectSection(
              icon: Icons.article_outlined,
              title: 'Memorial',
              subtitle: 'Memória de cálculo e documentação técnica.',
              enabled: false,
            ),
          ],
        ),
      );
}

class _ProjectSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ProjectSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          enabled: enabled,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: enabled ? onTap : null,
          trailing: enabled
              ? const Icon(Icons.chevron_right)
              : const Chip(label: Text('Em breve')),
        ),
      );
}
