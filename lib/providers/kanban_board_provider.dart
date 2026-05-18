import 'package:flutter/material.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/repositories/kanban_board_repository.dart';

class KanbanBoardProvider extends ChangeNotifier {
  final _repository = KanbanBoardRepository();

  final Map<String, List<KanbanCard>> _cardsByColumn = {
    'Todo': [],
    'In Progress': [],
    'Review': [],
    'Done': [],
  };

  List<KanbanCard> get todoCards => _cardsByColumn['Todo'] ?? [];
  List<KanbanCard> get inProgressCards => _cardsByColumn['In Progress'] ?? [];
  List<KanbanCard> get reviewCards => _cardsByColumn['Review'] ?? [];
  List<KanbanCard> get doneCards => _cardsByColumn['Done'] ?? [];

  List<KanbanCard> get allCards {
    final all = <KanbanCard>[];
    _cardsByColumn.forEach((_, cards) => all.addAll(cards));
    return all;
  }

  // Initialize listeners for each column
  void initialize() {
    for (final column in kKanbanColumns) {
      _repository.watchAllByColumn(column).listen((cards) {
        _cardsByColumn[column] = cards;
        notifyListeners();
      });
    }
  }

  Future<void> addCard(KanbanCard card) async {
    try {
      await _repository.add(card);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCard(KanbanCard card) async {
    try {
      await _repository.update(card);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> moveCard(String cardId, String newColumn, int newOrder) async {
    try {
      await _repository.moveCard(cardId, newColumn, newOrder);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _repository.delete(cardId);
    } catch (e) {
      rethrow;
    }
  }

  int getTotalCards() => allCards.length;
  int getCompletedCards() => doneCards.length;

  double getProgressPercentage() {
    if (allCards.isEmpty) return 0;
    return (doneCards.length / allCards.length) * 100;
  }
}
