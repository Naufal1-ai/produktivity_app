import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/budget_model.dart';

class BudgetRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('budgets');
  }

  /// Stream budget untuk bulan & tahun tertentu
  Stream<List<BudgetModel>> watchByMonth(DateTime month) {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col
        .where('year', isEqualTo: month.year)
        .where('month', isEqualTo: month.month)
        .snapshots()
        .map((snap) => snap.docs.map(BudgetModel.fromDoc).toList());
  }

  /// Upsert: jika sudah ada budget kategori ini di bulan tsb, update. Jika belum, add.
  Future<void> upsert(BudgetModel budget) async {
    final col = _col;
    if (col == null) return;

    final existing = await col
        .where('category', isEqualTo: budget.category)
        .where('year', isEqualTo: budget.year)
        .where('month', isEqualTo: budget.month)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({'limit': budget.limit});
    } else {
      await col.add(budget.toMap());
    }
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}
