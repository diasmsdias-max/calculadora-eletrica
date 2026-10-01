import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the relational V2 database.
///
/// V1 SharedPreferences repositories remain untouched while migration is
/// introduced incrementally. No caller should open the database directly.
class VisDatabase {
  static const databaseName = 'vis_electrica_v2.db';
  static const schemaVersion = 3;

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

    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
