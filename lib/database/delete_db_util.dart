import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

Future<void> deleteDatabaseManually() async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'energy_systems');
  await deleteDatabase(path);
  print("✅ Veritabanı silindi: $path");
}
