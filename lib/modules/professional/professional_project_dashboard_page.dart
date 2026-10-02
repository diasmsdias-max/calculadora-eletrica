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
import 'professional_materials_page.dart';
import 'professional_memorial_page.dart';
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
  late final Future<V2Persistence> _persistence;
  Map<String, String> _summaries = const {};

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _persistence = V2PersistenceFactory.defaults().initialize();
    _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    final persistence = await _persistence;
    final results = await Future.wait([
      persistence.professionalLoads.getByProject(_project.id),
      persistence.professionalCircuits.getByProject(_project.id),
      persistence.professionalBoards.getByProject(_project.id),
      persistence.professionalProtections.getByProject(_project.id),
      persistence.professionalSizing.getByProject(_project.id),
      persistence.professionalMaterials.getByProject(_project.id),
      persistence.professionalMemorials.getByProject(_project.id),
    ]);
    if (!mounted) return;
    setState(() {
      _summaries = {
        'Cargas': '${(results[0] as List).length} cadastrada(s)',
        'Circuitos': '${(results[1] as List).length} cadastrado(s)',
        'Quadros': '${(results[2] as List).length} cadastrado(s)',
        'Proteções': '${(results[3] as List).length} cadastrada(s)',
        'Dimensionamento': '${(results[4] as List).length} circuito(s) dimensionado(s)',
        'Materiais': '${(results[5] as List).length} item(ns)',
        'Memorial': results[6] == null ? 'Ainda não preenchido' : 'Memorial registrado',
      };
    });
  }

  String _sectionSubtitle(String title, String fallback) {
    final summary = _summaries[title];
    return summary == null ? fallback : '$fallback\n$summary';
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
              subtitle: _sectionSubtitle('Cargas', 'Cargas levantadas e vinculadas ao projeto.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
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
                await _loadSummaries();
              },
            ),
            _ProjectSection(
              icon: Icons.account_tree_outlined,
              title: 'Circuitos',
              subtitle: _sectionSubtitle('Circuitos', 'Agrupamento, alimentação e dados dos circuitos.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
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
                await _loadSummaries();
              },
            ),
            _ProjectSection(
              icon: Icons.dashboard_customize_outlined,
              title: 'Quadros',
              subtitle: _sectionSubtitle('Quadros', 'Quadros e distribuição dos circuitos.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfessionalBoardsPage(
                    repository: persistence.professionalBoards,
                    circuitsRepository: persistence.professionalCircuits,
                    projectId: _project.id,
                    readOnly: !widget.license.canEditProfessionalProjects,
                  ),
                ));
                await _loadSummaries();
              },
            ),
            _ProjectSection(
              icon: Icons.shield_outlined,
              title: 'Proteções',
              subtitle: _sectionSubtitle('Proteções', 'Proteções associadas aos circuitos.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfessionalProtectionsPage(
                    repository: persistence.professionalProtections,
                    circuitsRepository: persistence.professionalCircuits,
                    sizingRepository: persistence.professionalSizing,
                    projectId: _project.id,
                    readOnly: !widget.license.canEditProfessionalProjects,
                  ),
                ));
                await _loadSummaries();
              },
            ),
            _ProjectSection(
              icon: Icons.calculate_outlined,
              title: 'Dimensionamento',
              subtitle: _sectionSubtitle('Dimensionamento', 'Critérios e resultados técnicos do projeto.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfessionalSizingPage(
                    repository: persistence.professionalSizing,
                    circuitsRepository: persistence.professionalCircuits,
                    loadsRepository: persistence.professionalLoads,
                    projectId: _project.id,
                    readOnly: !widget.license.canEditProfessionalProjects,
                  ),
                ));
                await _loadSummaries();
              },
            ),
            _ProjectSection(
              icon: Icons.inventory_2_outlined,
              title: 'Materiais',
              subtitle: _sectionSubtitle('Materiais', 'Lista consolidada de materiais.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfessionalMaterialsPage(
                    repository: persistence.professionalMaterials,
                    projectId: _project.id,
                    readOnly: !widget.license.canEditProfessionalProjects,
                  ),
                ));
                await _loadSummaries();
              },
            ),
            _ProjectSection(
              icon: Icons.article_outlined,
              title: 'Memorial',
              subtitle: _sectionSubtitle('Memorial', 'Memória de cálculo e documentação técnica.'),
              enabled: true,
              onTap: () async {
                final persistence = await _persistence;
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfessionalMemorialPage(
                    repository: persistence.professionalMemorials,
                    projectId: _project.id,
                    readOnly: !widget.license.canEditProfessionalProjects,
                  ),
                ));
                await _loadSummaries();
              },
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
