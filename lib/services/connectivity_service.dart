import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/sync_repository.dart';
class ConnectivityService {
  ConnectivityService(this._sync);
  final SyncRepository _sync;
  final isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Future<void> start() async {
    _apply(await Connectivity().checkConnectivity());
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
  }
  void _apply(List<ConnectivityResult> res) {
    final online = !res.contains(ConnectivityResult.none);
    isOnline.value = online;
    if (online) unawaited(syncNow());
  }
  Future<void> syncNow() async {
    try {
      await _sync.sync();
    } catch (e) {
      debugPrint('sync falló: ${e.runtimeType}');
    }
  }
  void dispose() {
    _sub?.cancel();
    isOnline.dispose();
  }
}