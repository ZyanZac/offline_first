import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Future<Database>? _opening;
  Future<Database> get database => _opening ??= _open();
  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'offline_first.db');
    return openDatabase(path, version: 1, onCreate: (db, _) => db.execute(
      'CREATE TABLE tasks (id TEXT PRIMARY KEY, title TEXT NOT NULL, is_synced INTEGER DEFAULT 0, updated_at TEXT NOT NULL, is_deleted INTEGER DEFAULT 0)'));
  }
  Future<void> purge() async => (await database).delete('tasks');
}