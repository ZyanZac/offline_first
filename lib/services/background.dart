import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../bootstrap.dart';
import '../data/app_database.dart';
import '../data/remote_task_source.dart';
import '../data/sync_repository.dart';
import '../data/task_repository.dart';
const kSyncTask = 'com.chapulin.offlinefirst';
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await initFirebase();
      final sync = SyncRepository(
        TaskRepository(AppDatabase.instance),
        RemoteTaskSource(FirebaseAuth.instance, FirebaseFirestore.instance),
      );
      await sync.sync();
      return true;
    } catch (_) {
      return false;
    }
  });
}
Future<void> scheduleBackgroundSync() => Workmanager().registerOneOffTask(
      kSyncTask,
      kSyncTask,
      constraints: Constraints(networkType: NetworkType.connected),
    );