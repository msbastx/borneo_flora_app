import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database lokal aplikasi. Tetap tiga tabel sesuai rancangan skripsi:
/// identification_history, identification_suggestion, report_queue.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('borneo_flora.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE identification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        -- Legacy columns retained so existing v1 databases remain writable.
        result_status TEXT NOT NULL DEFAULT 'IDENTIFIED',
        ai_key INTEGER,
        identified_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        species_id INTEGER,
        predicted_label TEXT NOT NULL,
        confidence REAL NOT NULL,
        model_version TEXT,
        image_path TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        captured_at TEXT NOT NULL,
        is_saved INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE identification_suggestion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id INTEGER NOT NULL,
        ai_key INTEGER NOT NULL,
        label TEXT NOT NULL,
        confidence REAL NOT NULL,
        rank INTEGER NOT NULL,
        FOREIGN KEY (history_id) REFERENCES identification_history (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE report_queue (
        id TEXT PRIMARY KEY,
        history_id INTEGER,
        ai_key INTEGER,
        report_type TEXT NOT NULL,
        image_path TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        upload_status TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        allow_training INTEGER NOT NULL DEFAULT 0,
        confidence REAL,
        model_version TEXT,
        coordinate_approximate INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (history_id) REFERENCES identification_history (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_identification_suggestion_history_rank
      ON identification_suggestion(history_id, rank)
    ''');
    await db.execute('''
      CREATE INDEX idx_report_queue_status_created
      ON report_queue(upload_status, created_at)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // v1: original schema. v2 adds report fields; v3 normalizes history rows
    // and adds the candidate label required by identification_suggestion.
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE report_queue ADD COLUMN allow_training INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE report_queue ADD COLUMN confidence REAL');
      await db.execute('ALTER TABLE report_queue ADD COLUMN model_version TEXT');
      await db.execute(
        'ALTER TABLE report_queue ADD COLUMN coordinate_approximate INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE identification_history ADD COLUMN species_id INTEGER');
      await db.execute(
        "ALTER TABLE identification_history ADD COLUMN predicted_label TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('ALTER TABLE identification_history ADD COLUMN model_version TEXT');
      await db.execute(
        "ALTER TABLE identification_history ADD COLUMN captured_at TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE identification_history ADD COLUMN is_saved INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "ALTER TABLE identification_history ADD COLUMN created_at TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE identification_suggestion ADD COLUMN label TEXT NOT NULL DEFAULT ''",
      );

      // Backfill timestamps and a clearly provisional label for rows from v1.
      // Do not manufacture verified botanical metadata from ai_key alone.
      await db.execute('''
        UPDATE identification_history
        SET captured_at = CASE
              WHEN identified_at IS NOT NULL AND identified_at <> '' THEN identified_at
              ELSE datetime('now')
            END,
            created_at = CASE
              WHEN identified_at IS NOT NULL AND identified_at <> '' THEN identified_at
              ELSE datetime('now')
            END,
            predicted_label = CASE
              WHEN ai_key IS NOT NULL THEN 'Kelas AI ' || ai_key
              ELSE 'Hasil identifikasi lama'
            END
        WHERE captured_at = '' OR created_at = '' OR predicted_label = ''
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_identification_suggestion_history_rank
        ON identification_suggestion(history_id, rank)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_report_queue_status_created
        ON report_queue(upload_status, created_at)
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
