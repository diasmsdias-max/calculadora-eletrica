import 'package:flutter/material.dart';
import '../../core/database/v2_persistence_factory.dart';
import '../../core/licensing/license_state.dart';
import '../../core/professional/professional_project.dart';
import '../../core/professional/professional_project_repository.dart';
import 'professional_project_form_page.dart';

class ProfessionalProjectsPage extends StatefulWidget {
  final LicenseState license;
  const ProfessionalProjectsPage({super.key, required this.license});

  @override
  State<ProfessionalProjectsPage> createState() => _ProfessionalProjectsPageState();
}

class _ProfessionalProjectsPageState extends State<ProfessionalProjectsPage> {
  ProfessionalProjectRepository? _repository;
  List<ProfessionalProject> _projects = const [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final persistence = await V2PersistenceFactory.defaults().initialize();
    final projects = await persistence.professionalProjects.getAll();
    if (!mounted) return;
    setState(() {
      _repository = persistence.professionalProjects;
      _projects = projects;
      _loading = false;
    });
  }

  Future<void> _create() async {
    if (!widget.license.canEditProfessionalProjects || _repository == null) return;
    final now = DateTime.now().toUtc();
    final project = ProfessionalProject(
      id: _newProjectId(now),
      revision: 1,
      name: '',
      createdAt: now,
      updatedAt: now,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfessionalProjectFormPage(
          repository: _repository!,
          project: project,
          isNew: true,
        ),
      ),
    );
    await _load();
  }

  Future<void> _open(ProfessionalProject project) async {
    if (_repository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfessionalProjectFormPage(
          repository: _repository!,
          project: project,
          readOnly: !widget.license.canEditProfessionalProjects,
        ),
      ),
    );
    await _load();
  }

  String _newProjectId(DateTime now) =>
      'pro-${now.microsecondsSinceEpoch.toRadixString(36)}';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProfessionalProject> get _filteredProjects {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _projects;
    return _projects.where((project) {
      return project.name.toLowerCase().contains(query) ||
          project.client.toLowerCase().contains(query) ||
          project.address.toLowerCase().contains(query) ||
          project.responsible.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final projects = _filteredProjects;
    return Scaffold(
        appBar: AppBar(title: const Text('Projetos Elétricos')),
        floatingActionButton: widget.license.canEditProfessionalProjects
            ? FloatingActionButton.extended(
                onPressed: _loading ? null : _create,
                icon: const Icon(Icons.add),
                label: const Text('Novo projeto'),
              )
            : null,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        labelText: 'Buscar projetos',
                        hintText: 'Projeto, cliente, endereço ou responsável',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _projects.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        widget.license.canEditProfessionalProjects
                            ? 'Nenhum Projeto Profissional criado.\nUse “Novo projeto” para começar.'
                            : 'Nenhum Projeto Profissional salvo neste aparelho.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : projects.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Nenhum projeto encontrado para esta busca.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final subtitle = <String>[
                        if (project.client.isNotEmpty) project.client,
                        'Revisão ${project.revision}',
                      ].join(' • ');
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.electrical_services_outlined),
                          title: Text(project.name),
                          subtitle: Text(subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(project),
                        ),
                      );
                    },
                  ),
                    ),
                ],
              ),
      );
  }
}
