import '../professional/professional_profile.dart';
import '../professional/professional_profile_repository.dart';
import 'vis_backup_envelope.dart';
import 'vis_backup_service.dart';

/// Coordinates SQLite and Professional Profile restore as one recoverable unit.
///
/// Licensing is deliberately outside this coordinator and is never restored.
class VisBackupRestoreCoordinator {
  final VisBackupService backupService;
  final ProfessionalProfileRepository profileRepository;

  const VisBackupRestoreCoordinator({
    required this.backupService,
    required this.profileRepository,
  });

  Future<VisBackupEnvelope> restore(String source) async {
    final incoming = await backupService.validate(source);
    final incomingProfile = _profileFrom(incoming);

    // Snapshot the complete exportable local state before replacing anything.
    final previousProfile = await profileRepository.load();
    final rollbackSource = await backupService.createBackup(
      appVersion: 'rollback',
      professionalProfile:
          previousProfile?.toJson().cast<String, dynamic>(),
    );

    await backupService.restore(source);
    try {
      await _applyProfile(incomingProfile);
    } catch (_) {
      // Compensating rollback keeps SQLite + profile consistent even though
      // SharedPreferences cannot participate in the SQLite transaction.
      await backupService.restore(rollbackSource);
      await _applyProfile(previousProfile);
      rethrow;
    }

    return incoming;
  }

  ProfessionalProfile? _profileFrom(VisBackupEnvelope envelope) {
    final raw = envelope.payload['professionalProfile'];
    if (raw == null) return null;
    if (raw is! Map) {
      throw const FormatException('Perfil Profissional inválido.');
    }
    return ProfessionalProfile.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> _applyProfile(ProfessionalProfile? profile) =>
      profile == null
          ? profileRepository.clear()
          : profileRepository.save(profile);
}
