// =====================================
// lib/core/database/database_helper.dart
// =====================================
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meter_sync.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const realType = 'REAL';
    // const boolType = 'INTEGER';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType NOT NULL,
        full_name $textType,
        role $textType NOT NULL,
        access_token $textType,
        refresh_token $textType,
        created_at $textType NOT NULL
      )
    ''');

    // Meters table
    await db.execute('''
      CREATE TABLE meters (
        id $idType,
        meter_id_code $textType NOT NULL UNIQUE,
        meter_number $textType UNIQUE,
        type $textType,
        location_address $textType,
        client_name $textType,
        prev_reading_value $realType,
        last_reading_date $textType,
        status $textType DEFAULT 'active',
        meter_metadata $textType,
        created_at $textType NOT NULL,
        updated_at $textType NOT NULL,
        sync_status $textType DEFAULT 'synced'
      )
    ''');

    // Readings table
    await db.execute('''
      CREATE TABLE readings (
        id $idType,
        meter_id $textType NOT NULL,
        user_id $textType NOT NULL,
        reading_value $realType NOT NULL,
        reading_date $textType NOT NULL,
        reading_type $textType DEFAULT 'manual',
        device_id $textType,
        latitude $realType,
        longitude $realType,
        accuracy_meters $realType,
        notes $textType,
        sync_status $textType DEFAULT 'pending',
        client_id $textType UNIQUE,
        created_at $textType NOT NULL,
        updated_at $textType NOT NULL,
        photos $textType NOT NULL,
        FOREIGN KEY (meter_id) REFERENCES meters (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Outbox table for sync
    await db.execute('''
      CREATE TABLE outbox (
        id $idType,
        entity_type $textType NOT NULL,
        entity_id $textType NOT NULL,
        operation $textType NOT NULL,
        payload $textType NOT NULL,
        retry_count $intType DEFAULT 0,
        max_retries $intType DEFAULT 5,
        status $textType DEFAULT 'pending',
        error_message $textType,
        scheduled_at $textType NOT NULL,
        processed_at $textType,
        created_at $textType NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_meters_sync ON meters(sync_status)');
    await db.execute('CREATE INDEX idx_readings_sync ON readings(sync_status)');
    await db.execute('CREATE INDEX idx_readings_meter ON readings(meter_id)');
    await db.execute('CREATE INDEX idx_outbox_status ON outbox(status)');
    await db.execute('CREATE INDEX idx_meters_number ON meters(meter_number)');
    await db.execute('CREATE INDEX idx_meters_client ON meters(client_name)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add photos column to readings table
      await db.execute('''
        ALTER TABLE readings ADD COLUMN photos TEXT NOT NULL DEFAULT '[]'
      ''');
    }
  }

  Future<void> clearAllData() async {
    final db = await database;

    // Désactiver temporairement les contraintes de clé étrangère
    await db.execute('PRAGMA foreign_keys = OFF');

    // Liste des tables que tu veux vider
    final tables = ['meters', 'readings', 'outbox'];

    for (final table in tables) {
      await db.delete(table);
    }

    // Réactiver les contraintes
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<int> deleteMeter(String id) async {
    final db = await database;
    return db.delete('meters', where: "id = ?", whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
