import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/lending_model.dart';

class LendingRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('lendings');
  }

  /// Mendapatkan list peminjaman secara realtime, diurutkan dari yang belum kembali
  Stream<List<LendingModel>> watchAll() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col
        .snapshots() // ✅ FIX: Hapus orderBy agar tidak perlu Firestore index
        .map((snap) {
      final list = snap.docs.map(LendingModel.fromDoc).toList();
      // ✅ Sorting dilakukan di Flutter, hasil tetap sama
      list.sort((a, b) {
        if (a.isReturned != b.isReturned) {
          return a.isReturned ? 1 : -1; // Yang belum kembali (false) di atas
        }
        return a.targetReturnDate.compareTo(b.targetReturnDate);
      });
      return list;
    });
  }

  Future<void> add(LendingModel item) async {
    await _col?.add(item.toMap());
  }

  Future<void> update(LendingModel item) async {
    await _col?.doc(item.id).update(item.toMap());
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }

  Future<void> toggleStatus(String id, bool currentStatus) async {
    await _col?.doc(id).update({'isReturned': !currentStatus});
  }
}
