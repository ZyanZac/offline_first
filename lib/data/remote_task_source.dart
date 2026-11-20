import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
class RemoteTaskSource {
  RemoteTaskSource(this._auth, this._fs);
  final FirebaseAuth _auth;
  final FirebaseFirestore _fs;
  Future<CollectionReference<Map<String, dynamic>>> _col() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    return _fs.collection('users').doc(user.uid).collection('tasks');
  }
  Future<void> pushIfNewer(Task t) async {
    final ref = (await _col()).doc(t.id);
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists && DateTime.parse(snap.data()!['updated_at'] as String).isAfter(t.updatedAt)) return;
      tx.set(ref, t.toRemote());
    });
  }
  Future<List<Task>> fetchAll() async {
    final q = await (await _col()).get();
    return q.docs.map((d) => Task.fromRemote(d.data())).toList();
  }
}