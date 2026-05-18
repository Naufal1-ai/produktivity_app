import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/transaction_model.dart';

class TransactionRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('transactions');
  }

  Stream<List<TransactionModel>> watchAll() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map(TransactionModel.fromDoc).toList(),
        );
  }

  Stream<List<TransactionModel>> watchByMonth(DateTime month) {
    final col = _col;
    if (col == null) return Stream.value([]);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TransactionModel.fromDoc).toList());
  }

  Future<List<TransactionModel>> getAll() async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col.orderBy('date', descending: true).get();
    return snapshot.docs.map(TransactionModel.fromDoc).toList();
  }

  Future<void> add(TransactionModel tx) async {
    await _col?.add(tx.toMap());
  }

  Future<void> update(TransactionModel tx) async {
    final map = tx.toMap();
    map.remove('createdAt'); // don't overwrite
    await _col?.doc(tx.id).update(map);
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}
