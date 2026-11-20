import 'package:firebase_auth/firebase_auth.dart';
import '../data/app_database.dart';
import '../data/task_repository.dart';
class SessionService {
  SessionService(this._repo);
  final TaskRepository _repo;
  Future<void> signOutAndPurge() async {
    await FirebaseAuth.instance.signOut();
    await AppDatabase.instance.purge();
    await _repo.refresh();
  }
}