import 'dart:async';
import 'package:flutter/material.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/data/repositories/kanban_board_repository.dart';
import 'package:productivity/data/repositories/task_repository.dart';

class KanbanBoardProvider extends ChangeNotifier {
  final _repository = KanbanBoardRepository();
  final _taskRepository = TaskRepository();

  final List<StreamSubscription> _subscriptions = [];
  bool _initialized = false;

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
    if (_initialized) return;
    _initialized = true;

    _clearSubscriptions();

    for (final column in kKanbanColumns) {
      final sub = _repository.watchAllByColumn(column).listen((cards) {
        _cardsByColumn[column] = cards;
        notifyListeners();
      });
      _subscriptions.add(sub);
    }
  }

  void _clearSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }

  Future<void> addCard(KanbanCard card, {bool createLinkedTask = false}) async {
    try {
      String? taskId;
      if (createLinkedTask && card.dueDate != null) {
        final task = TaskModel(
          id: '',
          title: card.title,
          description: card.description,
          category: card.category ?? 'Pekerjaan',
          priority: card.priority ?? 'Medium',
          dueDate: card.dueDate!,
          completed: card.column == 'Done',
          createdAt: DateTime.now(),
        );
        taskId = await _taskRepository.add(task);
      }

      final cardToSave = card.copyWith(taskId: taskId);
      await _repository.add(cardToSave);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCard(KanbanCard card, {bool shouldLinkTask = false}) async {
    try {
      String? updatedTaskId = card.taskId;

      if (shouldLinkTask && card.dueDate != null) {
        if (updatedTaskId == null || updatedTaskId.isEmpty) {
          final task = TaskModel(
            id: '',
            title: card.title,
            description: card.description,
            category: card.category ?? 'Pekerjaan',
            priority: card.priority ?? 'Medium',
            dueDate: card.dueDate!,
            completed: card.column == 'Done',
            createdAt: DateTime.now(),
          );
          updatedTaskId = await _taskRepository.add(task);
        } else {
          final task = TaskModel(
            id: updatedTaskId,
            title: card.title,
            description: card.description,
            category: card.category ?? 'Pekerjaan',
            priority: card.priority ?? 'Medium',
            dueDate: card.dueDate!,
            completed: card.column == 'Done',
            createdAt: DateTime.now(),
          );
          await _taskRepository.update(task);
        }
      } else if (!shouldLinkTask && updatedTaskId != null && updatedTaskId.isNotEmpty) {
        await _taskRepository.delete(updatedTaskId);
        updatedTaskId = null;
      }

      final cardToSave = card.copyWith(taskId: updatedTaskId);
      await _repository.update(cardToSave);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> moveCard(String cardId, String newColumn, int newOrder) async {
    try {
      await _repository.moveCard(cardId, newColumn, newOrder);
      
      final card = allCards.where((c) => c.id == cardId).firstOrNull;
      if (card != null && card.taskId != null && card.taskId!.isNotEmpty) {
        final isCompleted = newColumn == 'Done';
        await _taskRepository.updateFields(card.taskId!, {
          'completed': isCompleted,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      final card = allCards.where((c) => c.id == cardId).firstOrNull;
      await _repository.delete(cardId);
      
      if (card != null && card.taskId != null && card.taskId!.isNotEmpty) {
        await _taskRepository.delete(card.taskId!);
      }
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
