import 'project_record_repository.dart';
import 'project_repository.dart';
import 'sqlite_project_repositories.dart';
import 'v1_to_v2_migration.dart';
import 'vis_database.dart';
import '../professional/professional_project_repository.dart';
import '../professional/sqlite_professional_project_repository.dart';
import '../professional/professional_load_repository.dart';
import '../professional/sqlite_professional_load_repository.dart';
import '../professional/professional_circuit_repository.dart';
import '../professional/sqlite_professional_circuit_repository.dart';
import '../professional/professional_board_repository.dart';
import '../professional/sqlite_professional_board_repository.dart';
import '../professional/professional_protection_repository.dart';
import '../professional/sqlite_professional_protection_repository.dart';
import '../professional/professional_sizing_repository.dart';
import '../professional/sqlite_professional_sizing_repository.dart';
import '../professional/professional_material_repository.dart';
import '../professional/sqlite_professional_material_repository.dart';
import '../professional/professional_memorial_repository.dart';
import '../professional/sqlite_professional_memorial_repository.dart';
import '../technical_center/technical_document_repository.dart';
import '../technical_center/sqlite_technical_document_repository.dart';

class V2Persistence {
  final ProjectRepository projects;
  final ProjectRecordRepository records;
  final ProfessionalProjectRepository professionalProjects;
  final ProfessionalLoadRepository professionalLoads;
  final ProfessionalCircuitRepository professionalCircuits;
  final ProfessionalBoardRepository professionalBoards;
  final ProfessionalProtectionRepository professionalProtections;
  final ProfessionalSizingRepository professionalSizing;
  final ProfessionalMaterialRepository professionalMaterials;
  final ProfessionalMemorialRepository professionalMemorials;
  final TechnicalDocumentRepository technicalDocuments;

  const V2Persistence({
    required this.projects,
    required this.records,
    required this.professionalProjects,
    required this.professionalLoads,
    required this.professionalCircuits,
    required this.professionalBoards,
    required this.professionalProtections,
    required this.professionalSizing,
    required this.professionalMaterials,
    required this.professionalMemorials,
    required this.technicalDocuments,
  });
}

/// Initializes V2 only after the legacy copy has completed successfully.
///
/// Keeping this bootstrap separate lets screens migrate incrementally while
/// V1 remains available as a recovery source during EP20.
class V2PersistenceFactory {
  final VisDatabase database;
  final ProjectRepository legacyProjects;
  final ProjectRecordRepository legacyRecords;

  const V2PersistenceFactory({
    required this.database,
    required this.legacyProjects,
    required this.legacyRecords,
  });

  factory V2PersistenceFactory.defaults() => V2PersistenceFactory(
    database: VisDatabase(),
    legacyProjects: PreferencesProjectRepository(),
    legacyRecords: PreferencesProjectRecordRepository(),
  );

  Future<V2Persistence> initialize() async {
    final db = await database.database;
    await V1ToV2Migration(
      database: db,
      legacyProjects: legacyProjects,
      legacyRecords: legacyRecords,
    ).migrateIfNeeded();

    return V2Persistence(
      projects: SqliteProjectRepository(db),
      records: SqliteProjectRecordRepository(db),
      professionalProjects: SqliteProfessionalProjectRepository(db),
      professionalLoads: SqliteProfessionalLoadRepository(db),
      professionalCircuits: SqliteProfessionalCircuitRepository(db),
      professionalBoards: SqliteProfessionalBoardRepository(db),
      professionalProtections: SqliteProfessionalProtectionRepository(db),
      professionalSizing: SqliteProfessionalSizingRepository(db),
      professionalMaterials: SqliteProfessionalMaterialRepository(db),
      professionalMemorials: SqliteProfessionalMemorialRepository(db),
      technicalDocuments: SqliteTechnicalDocumentRepository(db),
    );
  }
}
