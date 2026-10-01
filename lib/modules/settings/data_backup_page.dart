import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/backup/backup_preferences_repository.dart';
import '../../core/backup/vis_backup_envelope.dart';
import '../../core/backup/vis_backup_service.dart';
import '../../core/backup/vis_backup_restore_coordinator.dart';
import '../../core/database/vis_database.dart';
import '../../core/professional/professional_profile_repository.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  final _database = VisDatabase();
  final ProfessionalProfileRepository _profileRepository =
      LocalProfessionalProfileRepository();
  final BackupPreferencesRepository _preferencesRepository =
      const LocalBackupPreferencesRepository();
  bool _busy = false;

  Future<void> _createBackup() async {
    setState(() => _busy = true);
    try {
      final db = await _database.database;
      final profile = await _profileRepository.load();
      final package = await PackageInfo.fromPlatform();
      final preferences = await _preferencesRepository.export();
      final source = await VisBackupService(db).createBackup(
        appVersion: package.version,
        professionalProfile: profile?.toJson().cast<String, dynamic>(),
        preferences: preferences,
      );
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar backup VIS ELECTRICA',
        fileName: 'vis-electrica-$date.visbackup',
        type: FileType.custom,
        allowedExtensions: const ['visbackup'],
        bytes: utf8.encode(source),
      );
      if (path != null && mounted) {
        _message('Backup criado com sucesso.');
      }
    } catch (error) {
      if (mounted) _message('Não foi possível criar o backup: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _busy = true);
    try {
      final selection = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecionar backup VIS ELECTRICA',
        type: FileType.custom,
        allowedExtensions: const ['visbackup'],
        withData: true,
      );
      if (selection == null) return;
      final file = selection.files.single;
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        throw const FormatException('Não foi possível ler o arquivo.');
      }

      final source = utf8.decode(bytes);
      final db = await _database.database;
      final service = VisBackupService(db);
      final envelope = await service.validate(source);

      if (!mounted) return;
      final confirmed = await _confirmRestore(envelope);
      if (!confirmed) return;

      // Database replacement is atomic. Profile is intentionally separate
      // from licensing and is applied only after a validated restore.
      await VisBackupRestoreCoordinator(
        backupService: service,
        profileRepository: _profileRepository,
        preferencesRepository: _preferencesRepository,
      ).restore(source);

      if (mounted) _message('Backup restaurado com sucesso.');
    } on FormatException catch (error) {
      if (mounted) _message('Backup inválido: ${error.message}');
    } catch (error) {
      if (mounted) _message('Não foi possível restaurar o backup: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmRestore(VisBackupEnvelope envelope) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restaurar backup?'),
            content: Text(
              'Os projetos e dados técnicos atuais serão substituídos pelos '
              'dados deste backup.\n\n'
              'Criado em: ${envelope.createdAt.toLocal()}\n'
              'Versão do app: ${envelope.appVersion}\n\n'
              'A licença deste aparelho não será alterada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restaurar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados e Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'O backup manual protege seus projetos e dados técnicos. '
            'Licença, chave de ativação, tokens e credenciais não são '
            'incluídos no arquivo.',
          ),
          const SizedBox(height: 16),
          ListTile(
            enabled: !_busy,
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Criar backup'),
            subtitle: const Text('Salvar arquivo .visbackup neste dispositivo.'),
            onTap: _createBackup,
          ),
          ListTile(
            enabled: !_busy,
            leading: const Icon(Icons.restore_outlined),
            title: const Text('Restaurar backup'),
            subtitle: const Text(
              'Validar um .visbackup e substituir os dados locais após confirmação.',
            ),
            onTap: _restoreBackup,
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
