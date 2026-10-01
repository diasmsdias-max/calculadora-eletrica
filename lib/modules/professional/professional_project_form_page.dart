import 'package:flutter/material.dart';

import '../../core/professional/professional_project.dart';
import '../../core/professional/professional_project_repository.dart';

class ProfessionalProjectFormPage extends StatefulWidget {
  final ProfessionalProjectRepository repository;
  final ProfessionalProject project;
  final bool isNew;
  final bool readOnly;

  const ProfessionalProjectFormPage({
    super.key,
    required this.repository,
    required this.project,
    this.isNew = false,
    this.readOnly = false,
  });

  @override
  State<ProfessionalProjectFormPage> createState() => _ProfessionalProjectFormPageState();
}

class _ProfessionalProjectFormPageState extends State<ProfessionalProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _client;
  late final TextEditingController _address;
  late final TextEditingController _responsible;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.project.name);
    _client = TextEditingController(text: widget.project.client);
    _address = TextEditingController(text: widget.project.address);
    _responsible = TextEditingController(text: widget.project.responsible);
    _notes = TextEditingController(text: widget.project.notes);
  }

  Future<void> _save() async {
    if (widget.readOnly || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final project = ProfessionalProject(
      id: widget.project.id,
      revision: widget.isNew ? 1 : widget.project.revision + 1,
      name: _name.text,
      client: _client.text,
      address: _address.text,
      responsible: _responsible.text,
      notes: _notes.text,
      createdAt: widget.project.createdAt,
      updatedAt: DateTime.now().toUtc(),
    ).normalized();
    await widget.repository.save(project);
    if (!mounted) return;
    Navigator.of(context).pop(project);
  }

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _address.dispose();
    _responsible.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.isNew ? 'Novo Projeto' : widget.project.name),
          actions: [
            if (!widget.readOnly)
              IconButton(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Salvar',
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.readOnly)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Somente leitura'),
                    subtitle: Text('Ative o Profissional para editar este projeto.'),
                  ),
                ),
              TextFormField(
                controller: _name,
                readOnly: widget.readOnly,
                decoration: const InputDecoration(labelText: 'Nome do projeto', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome do projeto.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(controller: _client, readOnly: widget.readOnly, decoration: const InputDecoration(labelText: 'Cliente', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              TextFormField(controller: _address, readOnly: widget.readOnly, decoration: const InputDecoration(labelText: 'Endereço', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              TextFormField(controller: _responsible, readOnly: widget.readOnly, decoration: const InputDecoration(labelText: 'Responsável', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              TextFormField(controller: _notes, readOnly: widget.readOnly, maxLines: 4, decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              Text('ID: ${widget.project.id}', style: Theme.of(context).textTheme.bodySmall),
              Text('Revisão: ${widget.project.revision}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
