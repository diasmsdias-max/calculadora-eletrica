import 'package:flutter/material.dart';
import '../../core/database/local_project.dart';
import '../../core/database/project_repository.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});
  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final ProjectRepository repository = PreferencesProjectRepository();
  List<LocalProject> projects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await repository.getAll();
    if (!mounted) return;
    setState(() { projects = data; loading = false; });
  }

  Future<void> _edit([LocalProject? project]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectEditPage(repository: repository, project: project),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(LocalProject project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir projeto?'),
        content: Text('O projeto “${project.name}” será removido deste dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('EXCLUIR')),
        ],
      ),
    );
    if (ok == true) {
      await repository.delete(project.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus Projetos')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('Novo projeto'),
    ),
    body: SafeArea(
      top: false,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum projeto salvo.\nCrie um projeto para organizar os cálculos por cliente ou obra.', textAlign: TextAlign.center),
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: projects.length,
                  itemBuilder: (_, i) {
                    final p = projects[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(p.name),
                        subtitle: Text([
                          if (p.client.isNotEmpty) p.client,
                          if (p.address.isNotEmpty) p.address,
                        ].join('\n')),
                        onTap: () => _edit(p),
                        trailing: IconButton(
                          tooltip: 'Excluir',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(p),
                        ),
                      ),
                    );
                  },
                ),
    ),
  );
}

class ProjectEditPage extends StatefulWidget {
  final ProjectRepository repository;
  final LocalProject? project;
  const ProjectEditPage({super.key, required this.repository, this.project});

  @override
  State<ProjectEditPage> createState() => _ProjectEditPageState();
}

class _ProjectEditPageState extends State<ProjectEditPage> {
  late final TextEditingController name;
  late final TextEditingController client;
  late final TextEditingController address;
  late final TextEditingController responsible;
  late final TextEditingController notes;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    name = TextEditingController(text: p?.name ?? '');
    client = TextEditingController(text: p?.client ?? '');
    address = TextEditingController(text: p?.address ?? '');
    responsible = TextEditingController(text: p?.responsible ?? '');
    notes = TextEditingController(text: p?.notes ?? '');
  }

  Future<void> _save() async {
    final projectName = name.text.trim();
    if (projectName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome do projeto.')));
      return;
    }
    setState(() => saving = true);
    final now = DateTime.now();
    final old = widget.project;
    final project = LocalProject(
      id: old?.id ?? now.microsecondsSinceEpoch.toString(),
      name: projectName,
      client: client.text.trim(),
      address: address.text.trim(),
      responsible: responsible.text.trim(),
      notes: notes.text.trim(),
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    await widget.repository.save(project);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    for (final c in [name, client, address, responsible, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.project == null ? 'Novo Projeto' : 'Editar Projeto')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _field(name, 'Nome do projeto / obra *'),
          const SizedBox(height: 12),
          _field(client, 'Cliente'),
          const SizedBox(height: 12),
          _field(address, 'Endereço'),
          const SizedBox(height: 12),
          _field(responsible, 'Responsável'),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Observações', alignLabelWithHint: true),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'SALVANDO...' : 'SALVAR PROJETO'),
          ),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController controller, String label) => TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
  );
}
