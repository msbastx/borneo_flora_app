import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Mengaktifkan Foreign Key constraint di SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Riwayat Identifikasi (UC-01, UC-08)
    await db.execute('''
      CREATE TABLE identification_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        result_status TEXT NOT NULL,
        ai_key INTEGER,
        confidence REAL NOT NULL,
        latitude REAL,
        longitude REAL,
        identified_at TEXT NOT NULL
      )
    ''');

    // 2. Tabel Saran/Kandidat Identifikasi Top-3 (UC-01, MB-07)
    await db.execute('''
      CREATE TABLE identification_suggestion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        history_id INTEGER NOT NULL,
        ai_key INTEGER NOT NULL,
        confidence REAL NOT NULL,
        rank INTEGER NOT NULL,
        FOREIGN KEY (history_id) REFERENCES identification_history (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel Antrean Pengiriman Laporan (UC-03, UC-04, MB-18)
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
        FOREIGN KEY (history_id) REFERENCES identification_history (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}