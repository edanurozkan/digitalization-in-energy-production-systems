import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/energy_production_model.dart';
import '../models/notification_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'energy_data.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE energy_systems (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            system_name TEXT,
            latitude REAL,
            longitude REAL,
            capacity_kW REAL,
            tilt REAL,        
            azimuth REAL,
            created_at TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE energy_production (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            system_id INTEGER,
            month INTEGER,
            year INTEGER,
            energy_kWh REAL
          );
        ''');

        await db.execute('''
          CREATE TABLE notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            message TEXT,
            date TEXT,
            isRead INTEGER,
            importance TEXT
          );
        ''');
      },
    );

    return _db!;
  }

  static Future<void> insertEnergyProduction(
      EnergyProduction production) async {
    final db = await getDatabase();
    await db.insert(
      'energy_production',
      production.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllProductions() async {
    final db = await getDatabase();
    return await db.query('energy_production');
  }

  static Future<List<Map<String, dynamic>>> getAllProductionsForUser(
      int userId) async {
    final db = await getDatabase();
    return await db.rawQuery('''
      SELECT ep.* FROM energy_production ep
      JOIN energy_systems es ON ep.system_id = es.id
      WHERE es.user_id = ?
    ''', [userId]);
  }

  static Future<List<Map<String, dynamic>>> getSystemsByUserId(
      int userId) async {
    final db = await DBHelper.getDatabase();
    return await db.query(
      'energy_systems',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  static Future<int> addUser(String name, String email, String password) async {
    final db = await getDatabase();
    return await db.insert(
      'users',
      {'name': name, 'email': email, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<Map<String, dynamic>?> getUserByEmailAndPassword(
      String email, String password) async {
    final db = await getDatabase();
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await getDatabase();
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> addEnergySystem({
    required int userId,
    required String systemName,
    required double latitude,
    required double longitude,
    required double capacityKW,
    required double tilt,
    required double azimuth,
  }) async {
    final db = await getDatabase();
    await db.insert('energy_systems', {
      'user_id': userId,
      'system_name': systemName,
      'latitude': latitude,
      'longitude': longitude,
      'capacity_kW': capacityKW,
      'tilt': tilt,
      'azimuth': azimuth,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteEnergySystem(int id) async {
    final db = await getDatabase();
    await db.delete(
      'energy_systems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteProduction(int id) async {
    final db = await getDatabase();
    await db.delete(
      'energy_production',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateProduction(int id, double newEnergy) async {
    final db = await getDatabase();
    await db.update(
      'energy_production',
      {'energy_kWh': newEnergy},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getProductionsBySystem(
      int systemId) async {
    final db = await getDatabase();
    return await db.query(
      'energy_production',
      where: 'system_id = ?',
      whereArgs: [systemId],
    );
  }

  static Future<void> updateUser(String oldEmail, String newName,
      String newEmail, String newPassword) async {
    final db = await getDatabase();
    await db.update(
      'users',
      {
        'name': newName,
        'email': newEmail,
        'password': newPassword,
      },
      where: 'email = ?',
      whereArgs: [oldEmail],
    );
  }

  static Future<void> insertNotification(AppNotification notification) async {
    final db = await getDatabase();
    await db.insert('notifications', notification.toMap());
  }

  static Future<List<AppNotification>> getAllNotifications() async {
    final db = await getDatabase();
    final maps = await db.query('notifications', orderBy: 'date DESC');
    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }

  static Future<void> markAsRead(int id) async {
    final db = await getDatabase();
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearNotifications() async {
    final db = await getDatabase();
    await db.delete('notifications');
  }
}

// ✅ Veritabanını manuel silmek için
Future<void> deleteDatabaseManually() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'energy_data.db');
  await deleteDatabase(path);
  print("🗑️ Veritabanı dosyası tamamen silindi: $path");
}
