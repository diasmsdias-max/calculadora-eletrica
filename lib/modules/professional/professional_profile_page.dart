import 'package:flutter/material.dart';

import '../../core/professional/professional_profile.dart';
import '../../core/professional/professional_profile_repository.dart';

class ProfessionalProfilePage extends StatefulWidget {
  const ProfessionalProfilePage({super.key});

  @override
  State<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  final ProfessionalProfileRepository _repository =
      LocalProfessionalProfileRepository();
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _repository.load();
    if (!mounted) return;
    _companyController.text = profile?.companyName ?? '';
    _documentController.text = profile?.document ?? '';
    _phoneController.text = profile?.phone ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = ProfessionalProfile(
      companyName: _companyController.text,
      document: _documentController.text,
      phone: _phoneController.text,
    ).normalized();
    await _repository.save(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil Profissional salvo.')),
    );
    Navigator.of(context).pop(profile);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Perfil Profissional')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Identidade profissional',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O nome configurado substituirá BOECKER nos locais '
                      'Profissionais. VIS ELECTRICA continuará identificado '
                      'como o produto.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _companyController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome da empresa ou profissional',
                        hintText: 'Ex.: Elétrica São José',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Informe o nome que será exibido.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _documentController,
                      decoration: const InputDecoration(
                        labelText: 'CNPJ (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone/WhatsApp (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Salvando...' : 'Salvar perfil'),
                    ),
                  ],
                ),
              ),
      );
}
