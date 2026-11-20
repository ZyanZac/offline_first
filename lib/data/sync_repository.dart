import 'remote_task_source.dart';
import 'task_repository.dart';
class SyncRepository {
  SyncRepository(this._local, this._remote);
  final TaskRepository _local;
  final RemoteTaskSource _remote;
  bool _running = false;
  Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      await pushPending();
      await pullRemote();
    } finally {
      _running = false;
    }
  }
  Future<void> pushPending() async {
    for (final t in await _local.pending()) {
      await _remote.pushIfNewer(t);
      await _local.markSynced(t);
    }
  }
  Future<void> pullRemote() async {
    for (final r in await _remote.fetchAll()) {
      final l = await _local.byId(r.id);
      if (l == null || r.updatedAt.isAfter(l.updatedAt)) await _local.upsertRemote(r);
    }
    await _local.refresh();
  }
}