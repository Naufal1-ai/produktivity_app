import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/kanban_board_model.dart';

class KanbanBoardRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('kanban_cards');
  }

  // ✅ FIX: Hapus .orderBy agar tidak perlu Firestore index
  // Sorting dilakukan di sisi Flutter
  Stream<List<KanbanCard>> watchAllByColumn(String column) {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col.where('column', isEqualTo: column).snapshots().map((snap) {
      final list = snap.docs.map(KanbanCard.fromDoc).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  // ✅ FIX: Hapus .orderBy ganda, sorting di Flutter
  Stream<List<KanbanCard>> watchAll() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(KanbanCard.fromDoc).toList();
      list.sort((a, b) {
        final colCompare = a.column.compareTo(b.column);
        if (colCompare != 0) return colCompare;
        return a.order.compareTo(b.order);
      });
      return list;
    });
  }

  Future<void> add(KanbanCard card) async {
    await _col?.add(card.toMap());
  }

  Future<void> update(KanbanCard card) async {
    final data = card.toMap();
    data.remove('createdAt');
    await _col?.doc(card.id).update(data);
  }

  Future<void> moveCard(
    String cardId,
    String newColumn,
    int newOrder,
  ) async {
    await _col?.doc(cardId).update({
      'column': newColumn,
      'order': newOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}
