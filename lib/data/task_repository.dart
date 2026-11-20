import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import 'app_database.dart';
class TaskRepository {
  TaskRepository(this._appDb);
  final AppDatabase _appDb;
  final _controller = StreamController<List<Task>>.broadcast();
  Stream<List<Task>> watchAll() async* {
    yield await _visible();
    yield* _controller.stream;
  }
  Future<List<Task>> _visible() async {
    final db = await _appDb.database;
    final rows = await db.query('tasks', where: 'is_deleted = 0', orderBy: 'updated_at DESC');
    return rows.map(Task.fromMap).toList();
  }
  Future<void> refresh() async => _controller.add(await _visible());
  Future<void> saveLocal(Task t) async {
    final db = await _appDb.database;
    await db.insert('tasks', t.toMap(isSynced: false), conflictAlgorithm: ConflictAlgorithm.replace);
    await refresh();
  }
  Future<void> create(String title) =>
      saveLocal(Task(id: const Uuid().v4(), title: title, updatedAt: DateTime.now().toUtc()));
  Future<void> update(Task t, String title) =>
      saveLocal(t.copyWith(title: title, updatedAt: DateTime.now().toUtc()));
  Future<void> softDelete(Task t) =>
      saveLocal(t.copyWith(isDeleted: true, updatedAt: DateTime.now().toUtc()));
  Future<List<Task>> pending() async {
    final db = await _appDb.database;
    final rows = await db.query('tasks', where: 'is_synced = 0');
    return rows.map(Task.fromMap).toList();
  }
  Future<Task?> byId(String id) async {
    final db = await _appDb.database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Task.fromMap(rows.first);
  }
  Future<void> markSynced(Task t) async {
    final db = await _appDb.database;
    await db.update('tasks', {'is_synced': 1},
        where: 'id = ? AND updated_at = ?', whereArgs: [t.id, t.updatedAt.toUtc().toIso8601String()]);
    await refresh();
  }
  Future<void> upsertRemote(Task t) async {
    final db = await _appDb.database;
    await db.insert('tasks', t.toMap(isSynced: true), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}