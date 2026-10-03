import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the relational V2 database.
///
/// V1 SharedPreferences repositories remain untouched while migration is
/// introduced incrementally. No caller should open the database directly.
class VisDatabase {
  static const databaseName = 'vis_electrica_v2.db';
  static const schemaVersion = 15;

  Database? _database;

  Future<Database> get database async =>
      _database ??= await _open(await getDatabasesPath());

  Future<Database> _open(String rootPath) {
    return openDatabase(
      p.join(rootPath, databaseName),
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
  }

  Future<void> close() async {
    final current = _database;
    _database = null;
    await current?.close();
  }

  static Future<void> createSchemaForTesting(Database db) =>
      _createSchema(db, schemaVersion);

  static Future<void> upgradeSchemaForTesting(
    Database db,
    int oldVersion,
    int newVersion,
  ) => _upgradeSchema(db, oldVersion, newVersion);

  static Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createProfessionalProjectsTable(db);
    }
    if (oldVersion < 3) {
      await _createProfessionalLoadsTable(db);
    }
    if (oldVersion < 4) {
      await _createProfessionalCircuitsTables(db);
    }
    if (oldVersion < 5) {
      await _createProfessionalBoardsTables(db);
    }
    if (oldVersion < 6) {
      await _createProfessionalProtectionsTable(db);
    }
    if (oldVersion < 7) {
      await _createProfessionalSizingTable(db);
    }
    if (oldVersion < 8) {
      await _createProfessionalMaterialsTable(db);
    }
    if (oldVersion < 9) {
      await _createProfessionalMemorialTable(db);
    }
    if (oldVersion < 10) {
      await _addProfessionalProtectionValidationColumns(db);
    }
    if (oldVersion < 11) {
      await _addProfessionalSizingAmpacityColumn(db);
    }
    if (oldVersion < 12) {
      await _addProfessionalLoadSimultaneityColumns(db);
    }
    if (oldVersion < 13) {
      await _addProfessionalProtectionRoleColumn(db);
    }
    if (oldVersion < 14) {
      await _createTechnicalDocumentsTable(db);
    }
    if (oldVersion < 15) {
      await _enforceSingleCircuitPerLoad(db);
    }
  }

  static Future<void> _createProfessionalProjectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE professional_projects (
        id TEXT PRIMARY KEY,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        name TEXT NOT NULL,
        client TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        responsible TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_projects_updated_at '
      'ON professional_projects(updated_at DESC)',
    );
  }

  static Future<void> _createProfessionalLoadsTable(Database db) async {
    await db.execute('''
      CREATE TABLE professional_loads (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        quantity INTEGER NOT NULL DEFAULT 1,
        power_w REAL NOT NULL DEFAULT 0,
        voltage_v REAL NOT NULL DEFAULT 0,
        power_factor REAL,
        simultaneity_factor REAL,
        simultaneity_source TEXT,
        simultaneity_basis TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_loads_project_id '
      'ON professional_loads(project_id)',
    );
  }

  static Future<void> _createProfessionalCircuitsTables(Database db) async {
    await db.execute('''
      CREATE TABLE professional_circuits (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        voltage_v REAL,
        phases INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_circuits_project_id '
      'ON professional_circuits(project_id)',
    );
    await db.execute('''
      CREATE TABLE professional_circuit_loads (
        circuit_id TEXT NOT NULL,
        load_id TEXT NOT NULL UNIQUE,
        PRIMARY KEY (circuit_id, load_id),
        FOREIGN KEY (circuit_id) REFERENCES professional_circuits(id) ON DELETE CASCADE,
        FOREIGN KEY (load_id) REFERENCES professional_loads(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _enforceSingleCircuitPerLoad(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'professional_circuit_loads'",
    );
    if (tables.isEmpty) return;

    // Legacy builds allowed one load to be linked to more than one circuit.
    // Keep the oldest deterministic relation and remove only duplicates before
    // enforcing the domain rule at database level.
    await db.execute('''
      DELETE FROM professional_circuit_loads
      WHERE rowid NOT IN (
        SELECT MIN(rowid)
        FROM professional_circuit_loads
        GROUP BY load_id
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS '
      'idx_professional_circuit_loads_load_id '
      'ON professional_circuit_loads(load_id)',
    );
  }

  static Future<void> _createProfessionalBoardsTables(Database db) async {
    await db.execute('''
      CREATE TABLE professional_boards (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_boards_project_id '
      'ON professional_boards(project_id)',
    );
    await db.execute('''
      CREATE TABLE professional_board_circuits (
        board_id TEXT NOT NULL,
        circuit_id TEXT NOT NULL UNIQUE,
        PRIMARY KEY (board_id, circuit_id),
        FOREIGN KEY (board_id) REFERENCES professional_boards(id) ON DELETE CASCADE,
        FOREIGN KEY (circuit_id) REFERENCES professional_circuits(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createProfessionalProtectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE professional_protections (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        circuit_id TEXT NOT NULL,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        name TEXT NOT NULL,
        device_type TEXT NOT NULL DEFAULT '',
        protection_role TEXT,
        rated_current_a REAL,
        recommended_current_a REAL,
        validation_status TEXT,
        validation_criterion TEXT NOT NULL DEFAULT '',
        poles INTEGER,
        trip_curve TEXT NOT NULL DEFAULT '',
        breaking_capacity_ka REAL,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE,
        FOREIGN KEY (circuit_id) REFERENCES professional_circuits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_protections_project_id '
      'ON professional_protections(project_id)',
    );
    await db.execute(
      'CREATE INDEX idx_professional_protections_circuit_id '
      'ON professional_protections(circuit_id)',
    );
  }

  static Future<void> _addProfessionalProtectionValidationColumns(
    Database db,
  ) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'professional_protections'",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery(
      'PRAGMA table_info(professional_protections)',
    );
    final names = columns.map((row) => row['name'] as String).toSet();

    if (!names.contains('recommended_current_a')) {
      await db.execute(
        'ALTER TABLE professional_protections '
        'ADD COLUMN recommended_current_a REAL',
      );
    }
    if (!names.contains('validation_status')) {
      await db.execute(
        'ALTER TABLE professional_protections '
        'ADD COLUMN validation_status TEXT',
      );
    }
    if (!names.contains('validation_criterion')) {
      await db.execute(
        'ALTER TABLE professional_protections '
        "ADD COLUMN validation_criterion TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  static Future<void> _addProfessionalSizingAmpacityColumn(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'professional_sizing'",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery('PRAGMA table_info(professional_sizing)');
    final names = columns.map((row) => row['name'] as String).toSet();
    if (!names.contains('conductor_ampacity_a')) {
      await db.execute(
        'ALTER TABLE professional_sizing '
        'ADD COLUMN conductor_ampacity_a REAL',
      );
    }
  }

  static Future<void> _addProfessionalLoadSimultaneityColumns(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'professional_loads'",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery('PRAGMA table_info(professional_loads)');
    final names = columns.map((row) => row['name'] as String).toSet();
    if (!names.contains('simultaneity_factor')) {
      await db.execute(
        'ALTER TABLE professional_loads ADD COLUMN simultaneity_factor REAL',
      );
    }
    if (!names.contains('simultaneity_source')) {
      await db.execute(
        'ALTER TABLE professional_loads ADD COLUMN simultaneity_source TEXT',
      );
    }
    if (!names.contains('simultaneity_basis')) {
      await db.execute(
        'ALTER TABLE professional_loads '
        "ADD COLUMN simultaneity_basis TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  static Future<void> _addProfessionalProtectionRoleColumn(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'professional_protections'",
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery(
      'PRAGMA table_info(professional_protections)',
    );
    final names = columns.map((row) => row['name'] as String).toSet();
    if (!names.contains('protection_role')) {
      await db.execute(
        'ALTER TABLE professional_protections ADD COLUMN protection_role TEXT',
      );
    }
  }

  static Future<void> _createProfessionalSizingTable(Database db) async {
    await db.execute('''
      CREATE TABLE professional_sizing (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        circuit_id TEXT NOT NULL UNIQUE,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        design_current_a REAL,
        conductor_section_mm2 REAL,
        conductor_ampacity_a REAL,
        voltage_drop_percent REAL,
        protection_current_a REAL,
        method TEXT NOT NULL DEFAULT '',
        criteria TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE,
        FOREIGN KEY (circuit_id) REFERENCES professional_circuits(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_sizing_project_id '
      'ON professional_sizing(project_id)',
    );
  }

  static Future<void> _createProfessionalMaterialsTable(Database db) async {
    await db.execute('''
      CREATE TABLE professional_materials (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        unit TEXT NOT NULL DEFAULT '',
        quantity REAL,
        source TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_professional_materials_project_id '
      'ON professional_materials(project_id)',
    );
  }

  static Future<void> _createProfessionalMemorialTable(Database db) async {
    await db.execute('''
      CREATE TABLE professional_memorials (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL UNIQUE,
        contract_version INTEGER NOT NULL,
        revision INTEGER NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        scope TEXT NOT NULL DEFAULT '',
        criteria TEXT NOT NULL DEFAULT '',
        conclusions TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES professional_projects(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createTechnicalDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS technical_documents (
        id TEXT PRIMARY KEY,
        contract_version INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        manufacturer TEXT NOT NULL DEFAULT '',
        equipment_type TEXT NOT NULL DEFAULT '',
        model TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        remote_path TEXT NOT NULL DEFAULT '',
        file_name TEXT NOT NULL DEFAULT '',
        mime_type TEXT NOT NULL DEFAULT 'application/pdf',
        checksum TEXT NOT NULL DEFAULT '',
        size_bytes INTEGER,
        availability TEXT NOT NULL DEFAULT 'remoteOnly',
        local_path TEXT,
        keep_offline INTEGER NOT NULL DEFAULT 0,
        published_at TEXT,
        downloaded_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_technical_documents_category '
      'ON technical_documents(category)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_technical_documents_manufacturer_model '
      'ON technical_documents(manufacturer, model)',
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        client TEXT NOT NULL DEFAULT '',
        address TEXT NOT NULL DEFAULT '',
        responsible TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE project_records (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        summary TEXT NOT NULL DEFAULT '',
        data_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_project_records_project_id '
      'ON project_records(project_id)',
    );

    // Tables below establish stable relational boundaries for Professional
    // data. Their domain behavior is implemented by later EPs.
    await db.execute('''
      CREATE TABLE loads (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        circuit_id TEXT,
        data_json TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE circuits (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        board_id TEXT,
        data_json TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE boards (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE protections (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        circuit_id TEXT,
        board_id TEXT,
        data_json TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE material_items (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        data_json TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');
    await _createProfessionalProjectsTable(db);
    await _createProfessionalLoadsTable(db);
    await _createProfessionalCircuitsTables(db);
    await _createProfessionalBoardsTables(db);
    await _createProfessionalProtectionsTable(db);
    await _createProfessionalSizingTable(db);
    await _createProfessionalMaterialsTable(db);
    await _createProfessionalMemorialTable(db);
    await _createTechnicalDocumentsTable(db);

    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
