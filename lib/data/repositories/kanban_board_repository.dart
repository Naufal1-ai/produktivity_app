import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/board_model.dart';
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

  CollectionReference? get _boardsCol {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('kanban_boards');
  }

  // === BOARD METHODS ===

  Stream<List<BoardModel>> watchBoards() {
    final col = _boardsCol;
    if (col == null) return Stream.value([]);
    return col.orderBy('createdAt', descending: false).snapshots().map((snap) {
      return snap.docs.map(BoardModel.fromDoc).toList();
    });
  }

  Future<String> addBoard(BoardModel board) async {
    final col = _boardsCol;
    if (col == null) return '';
    final docRef = board.id.isNotEmpty ? col.doc(board.id) : col.doc();
    await docRef.set(board.toMap());
    return docRef.id;
  }

  Future<void> updateBoard(BoardModel board) async {
    final col = _boardsCol;
    if (col == null) return;
    final data = board.toMap();
    data.remove('createdAt');
    await col.doc(board.id).update(data);
  }

  Future<void> deleteBoard(String id) async {
    final col = _boardsCol;
    if (col == null) return;
    await col.doc(id).delete();
  }

  // === CARD METHODS ===

  Stream<List<KanbanCard>> watchAllByColumn(String boardId, String column) {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col
        .where('boardId', isEqualTo: boardId)
        .where('column', isEqualTo: column)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(KanbanCard.fromDoc).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Stream<List<KanbanCard>> watchAll(String boardId, {String? fallbackBoardId}) {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(KanbanCard.fromDoc).toList();
      final filteredList = list.where((card) {
        if (card.boardId == boardId) return true;
        if (card.boardId == 'default' && boardId == fallbackBoardId) return true;
        return false;
      }).toList();
      
      filteredList.sort((a, b) {
        final colCompare = a.column.compareTo(b.column);
        if (colCompare != 0) return colCompare;
        return a.order.compareTo(b.order);
      });
      return filteredList;
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
