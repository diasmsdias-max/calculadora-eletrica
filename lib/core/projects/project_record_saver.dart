import 'package:flutter/material.dart';
import '../database/local_project.dart';
import '../database/project_record.dart';
import '../database/project_record_repository.dart';
import '../database/project_repository.dart';
import '../database/v2_persistence_factory.dart';

class ProjectRecordSaver {
  static Future<bool> save(
    BuildContext context, {
    required ProjectRecordType type,
    required String title,
    required String summary,
    required Map<String, dynamic> data,
  }) async {
    final persistence = await V2PersistenceFactory.defaults().initialize();
    final projects = await persistence.projects.getAll();
    if (!context.mounted) return false;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie um projeto em Meus Projetos antes de salvar o cálculo.')),
      );
      return false;
    }
    final selected = await showDialog<LocalProject>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Salvar em qual projeto?'),
        children: projects.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(p.client.isEmpty ? p.name : '${p.name}\n${p.client}'),
          ),
        )).toList(),
      ),
    );
    if (selected == null) return false;
    final now = DateTime.now();
    await persistence.records.save(ProjectRecord(
      id: now.microsecondsSinceEpoch.toString(),
      projectId: selected.id,
      type: type,
      title: title,
      summary: summary,
      data: data,
      createdAt: now,
    ));
    await persistence.projects.save(selected.copyWith(updatedAt: now));
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cálculo salvo em “${selected.name}”.')),
    );
    return true;
  }
}
