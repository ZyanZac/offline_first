import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/app_database.dart';
import '../data/remote_task_source.dart';
import '../data/sync_repository.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../services/background.dart';
import '../services/connectivity_service.dart';
import '../services/session_service.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _repo = TaskRepository(AppDatabase.instance);
  late final _net = ConnectivityService(
      SyncRepository(_repo, RemoteTaskSource(FirebaseAuth.instance, FirebaseFirestore.instance)));
  late final Stream<List<Task>> _stream = _repo.watchAll();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _net.start();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _repo.refresh();
      if (_net.isOnline.value) unawaited(_net.syncNow());
    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _net.dispose();
    super.dispose();
  }
  Future<void> _afterWrite() async {
    unawaited(scheduleBackgroundSync());
    if (_net.isOnline.value) unawaited(_net.syncNow());
  }
  Future<void> _edit([Task? t]) async {
    final c = TextEditingController(text: t?.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t == null ? 'Nueva tarea' : 'Editar tarea'),
        content: TextField(controller: c, maxLength: 200, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    final title = c.text.trim();
    if (ok != true || title.isEmpty) return;
    t == null ? await _repo.create(title) : await _repo.update(t, title);
    await _afterWrite();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Tareas Offline-First'),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _net.isOnline,
              builder: (_, on, __) => Icon(on ? Icons.cloud_done : Icons.cloud_off),
            ),
            IconButton(icon: const Icon(Icons.sync), onPressed: _net.syncNow),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => SessionService(_repo).signOutAndPurge()),
          ],
        ),
        body: Column(children: [
          ValueListenableBuilder<bool>(
            valueListenable: _net.isOnline,
            builder: (_, on, __) => on
                ? const SizedBox.shrink()
                : const MaterialBanner(
                    content: Text('Sin conexión: los cambios se guardan localmente'), actions: [SizedBox()]),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _stream,
              builder: (_, s) {
                final items = s.data ?? const <Task>[];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final t = items[i];
                    return ListTile(
                      title: Text(t.title),
                      leading: Icon(t.isSynced ? Icons.check_circle : Icons.schedule),
                      onTap: () => _edit(t),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _repo.softDelete(t);
                          await _afterWrite();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
        floatingActionButton: FloatingActionButton(onPressed: _edit, child: const Icon(Icons.add)),
      );
}