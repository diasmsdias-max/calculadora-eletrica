import 'package:flutter/material.dart';
import '../../core/database/local_project.dart';
import '../../core/database/project_record.dart';
import '../../core/database/project_record_repository.dart';
import '../../core/database/project_repository.dart';
import '../../core/pdf/project_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'projects_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final LocalProject project;
  final ProjectRepository projectRepository;
  const ProjectDetailPage({
    super.key,
    required this.project,
    required this.projectRepository,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final ProjectRecordRepository recordsRepository =
      PreferencesProjectRecordRepository();
  late LocalProject project;
  List<ProjectRecord> records = [];
  bool loading = true;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    project = widget.project;
    _load();
  }

  Future<void> _load() async {
    final data = await recordsRepository.getByProject(project.id);
    if (!mounted) return;
    setState(() { records = data; loading = false; });
  }

  Future<void> _editProject() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectEditPage(
          repository: widget.projectRepository,
          project: project,
        ),
      ),
    );
    if (saved == true) {
      final all = await widget.projectRepository.getAll();
      final updated = all.where((p) => p.id == project.id).firstOrNull;
      if (updated != null && mounted) {
        setState(() { project = updated; changed = true; });
      }
    }
  }

  Future<void> _deleteRecord(ProjectRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: Text('“${record.title}” será removido deste projeto.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('EXCLUIR')),
        ],
      ),
    );
    if (ok == true) {
      await recordsRepository.delete(record.id);
      await _load();
    }
  }

  Future<void> _sharePdf() async {
    try {
      final latestRecords = await recordsRepository.getByProject(project.id);
      final bytes = await ProjectPdfGenerator.generate(
        project: project,
        records: latestRecords,
      );
      if (!mounted) return;
      final safeName = project.name
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'relatorio_${safeName.isEmpty ? project.id : safeName}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $e')),
      );
    }
  }

  String _typeLabel(ProjectRecordType type) => switch (type) {
    ProjectRecordType.motor => 'Motor',
    ProjectRecordType.transformer => 'Transformador',
    ProjectRecordType.motorTransformer => 'Motor × Transformador',
    ProjectRecordType.loadSurvey => 'Levantamento de Cargas',
    ProjectRecordType.cableSizing => 'Dimensionamento de Cabos',
    ProjectRecordType.voltageDrop => 'Queda de Tensão',
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) Navigator.pop(context, changed);
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: 'Editar projeto',
            onPressed: _editProject,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text('Dados do projeto', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (project.client.isNotEmpty) _info('Cliente', project.client),
            if (project.address.isNotEmpty) _info('Endereço', project.address),
            if (project.responsible.isNotEmpty) _info('Responsável', project.responsible),
            if (project.notes.isNotEmpty) _info('Observações', project.notes),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: loading ? null : _sharePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('GERAR / COMPARTILHAR PDF'),
            ),
            const SizedBox(height: 20),
            Text('Registros técnicos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (records.isEmpty)
              const Card(child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Nenhum cálculo salvo neste projeto ainda.\n'
                  'Os módulos de cálculo serão vinculados aqui.',
                  textAlign: TextAlign.center,
                ),
              ))
            else
              ...records.map((r) => Card(
                child: ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(r.title),
                  subtitle: Text('${_typeLabel(r.type)}\n${r.summary}'),
                  isThreeLine: r.summary.isNotEmpty,
                  trailing: IconButton(
                    tooltip: 'Excluir registro',
                    onPressed: () => _deleteRecord(r),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              )),
          ],
        ),
      ),
    ),
  );

  Widget _info(String label, String value) => Card(
    child: ListTile(
      title: Text(label),
      subtitle: Text(value),
    ),
  );
}
