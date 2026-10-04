import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/database/v2_persistence_factory.dart';
import '../../core/licensing/license_state.dart';
import '../../core/professional/professional_project.dart';
import '../../core/professional/professional_project_repository.dart';
import 'professional_project_form_page.dart';
import 'professional_project_dashboard_page.dart';

class ProfessionalProjectsPage extends StatefulWidget {
  final LicenseState license;
  const ProfessionalProjectsPage({super.key, required this.license});

  @override
  State<ProfessionalProjectsPage> createState() => _ProfessionalProjectsPageState();
}

class _ProfessionalProjectsPageState extends State<ProfessionalProjectsPage> {
  ProfessionalProjectRepository? _repository;
  V2Persistence? _persistence;
  List<ProfessionalProject> _projects = const [];
  Map<String, ({int loads, int circuits, int boards})> _projectCounts = const {};
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
    final counts = <String, ({int loads, int circuits, int boards})>{};
    for (final project in projects) {
      final results = await Future.wait([
        persistence.professionalLoads.getByProject(project.id),
        persistence.professionalCircuits.getByProject(project.id),
        persistence.professionalBoards.getByProject(project.id),
      ]);
      counts[project.id] = (
        loads: results[0].length,
        circuits: results[1].length,
        boards: results[2].length,
      );
    }
    if (!mounted) return;
    setState(() {
      _repository = persistence.professionalProjects;
      _persistence = persistence;
      _projects = projects;
      _projectCounts = counts;
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

  Future<void> _importProject() async {
    if (!widget.license.canEditProfessionalProjects || _persistence == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['visproject'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) return;
    try {
      await _persistence!.projectTransfer.importProject(utf8.decode(bytes));
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Projeto importado com sucesso.')));
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo de projeto inválido: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível importar este projeto.')));
    }
  }

  Future<void> _exportProject(ProfessionalProject project) async {
    if (_persistence == null) return;
    final source = await _persistence!.projectTransfer.exportProject(project.id);
    final safeName = project.name.trim().isEmpty
        ? 'projeto-vis'
        : project.name.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar projeto VIS',
      fileName: '$safeName.visproject',
      type: FileType.custom,
      allowedExtensions: const ['visproject'],
      bytes: Uint8List.fromList(utf8.encode(source)),
    );
    if (!mounted || path == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Projeto exportado com sucesso.')));
  }

  Future<void> _showProjectActions(ProfessionalProject project) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Abrir projeto'),
              onTap: () => Navigator.of(context).pop('open'),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Exportar projeto'),
              onTap: () => Navigator.of(context).pop('export'),
            ),
            if (widget.license.canEditProfessionalProjects)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Deletar projeto'),
                subtitle: const Text('Apaga todos os dados deste projeto'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'open':
        await _open(project);
        break;
      case 'export':
        await _exportProject(project);
        break;
      case 'delete':
        await _confirmDeleteProject(project);
        break;
    }
  }

  Future<void> _confirmDeleteProject(ProfessionalProject project) async {
    if (_persistence == null || !mounted) return;
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Deletar projeto completo?'),
        content: Text(
          'Todas as informações de “${project.name}” serão apagadas: cargas, '
          'circuitos, quadros, proteções, dimensionamentos, materiais e memorial.\n\n'
          'Esta ação não pode ser desfeita dentro do app. A recuperação só será '
          'possível importando um arquivo .visproject exportado anteriormente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmação final'),
        content: Text(
          'Confirma a exclusão definitiva de “${project.name}” e de todos os '
          'dados vinculados a este projeto?\n\nNão há como desfazer esta operação.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não, manter projeto')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim, deletar tudo')),
        ],
      ),
    );
    if (second != true || !mounted) return;

    try {
      final deleted = await _persistence!.projectDeletion.deleteProject(project.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(deleted ? 'Projeto deletado definitivamente.' : 'Projeto não encontrado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível deletar o projeto. Nenhuma exclusão parcial foi mantida.')),
      );
    }
  }

  Future<void> _open(ProfessionalProject project) async {
    if (_repository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfessionalProjectDashboardPage(
          repository: _repository!,
          project: project,
          license: widget.license,
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
        appBar: AppBar(
          title: const Text('Projetos Elétricos'),
          actions: [
            if (widget.license.canEditProfessionalProjects)
              IconButton(
                tooltip: 'Importar projeto',
                onPressed: _loading ? null : _importProject,
                icon: const Icon(Icons.file_download_outlined),
              ),
          ],
        ),
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
                      final counts = _projectCounts[project.id];
                      final subtitle = counts == null
                          ? '0 cargas • 0 circuitos • 0 quadros'
                          : '${counts.loads} cargas • ${counts.circuits} circuitos • ${counts.boards} quadros';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.electrical_services_outlined),
                          title: Text(project.name),
                          subtitle: Text(subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(project),
                          onLongPress: () => _showProjectActions(project),
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
