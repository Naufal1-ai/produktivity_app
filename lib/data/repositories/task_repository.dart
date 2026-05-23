import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/task_model.dart';

class TaskRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('tasks');
  }

  Stream<List<TaskModel>> watchAll() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col
        .orderBy('completed')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromDoc).toList());
  }

  Future<String> add(TaskModel task) async {
    final col = _col;
    if (col == null) return '';
    final docRef = col.doc();
    await docRef.set(task.toMap());
    return docRef.id;
  }

  Future<void> update(TaskModel task) async {
    final data = task.toMap();
    data.remove('createdAt');
    await _col?.doc(task.id).update(data);
  }

  Future<void> updateFields(String id, Map<String, dynamic> data) async {
    await _col?.doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}
