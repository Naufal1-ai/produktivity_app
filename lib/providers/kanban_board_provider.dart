import 'dart:async';
import 'package:flutter/material.dart';
import 'package:productivity/data/models/board_model.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/data/repositories/kanban_board_repository.dart';
import 'package:productivity/data/repositories/task_repository.dart';

class KanbanBoardProvider extends ChangeNotifier {
  final _repository = KanbanBoardRepository();
  final _taskRepository = TaskRepository();

  bool _initialized = false;
  List<BoardModel> _boards = [];
  BoardModel? _activeBoard;

  StreamSubscription? _boardsSubscription;
  final List<StreamSubscription> _cardsSubscriptions = [];

  final Map<String, List<KanbanCard>> _cardsByColumn = {};

  List<BoardModel> get boards => _boards;
  BoardModel? get activeBoard => _activeBoard;

  List<KanbanCard> getCardsForColumn(String column) => _cardsByColumn[column] ?? [];

  List<KanbanCard> get allCards {
    final all = <KanbanCard>[];
    _cardsByColumn.forEach((_, cards) => all.addAll(cards));
    return all;
  }

  // Initialize listeners
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _boardsSubscription?.cancel();
    _boardsSubscription = _repository.watchBoards().listen((boardsList) async {
      _boards = boardsList;

      if (boardsList.isEmpty) {
        // Create default board if none exists
        final defaultBoard = BoardModel(
          id: 'default',
          name: 'Papan Utama',
          description: 'Papan aktivitas utama Anda',
          colorIndex: 0,
          columns: ['Todo', 'In Progress', 'Review', 'Done'],
          createdAt: DateTime.now(),
        );
        await _repository.addBoard(defaultBoard);
        return;
      }

      // Set active board
      if (_activeBoard == null || !boardsList.any((b) => b.id == _activeBoard!.id)) {
        _activeBoard = boardsList.first;
      } else {
        _activeBoard = boardsList.firstWhere((b) => b.id == _activeBoard!.id);
      }

      _listenToActiveBoardCards();
      notifyListeners();
    });
  }

  void _listenToActiveBoardCards() {
    for (final sub in _cardsSubscriptions) {
      sub.cancel();
    }
    _cardsSubscriptions.clear();

    final board = _activeBoard;
    if (board == null) return;

    final fallbackBoardId = _boards.isNotEmpty ? _boards.first.id : 'default';

    final sub = _repository.watchAll(board.id, fallbackBoardId: fallbackBoardId).listen((allCardsList) {
      _cardsByColumn.clear();

      // Initialize columns list for active board
      for (final col in board.columns) {
        _cardsByColumn[col] = [];
      }

      // Group cards
      for (final card in allCardsList) {
        final colName = board.columns.contains(card.column) ? card.column : board.columns.first;
        _cardsByColumn[colName] ??= [];
        _cardsByColumn[colName]!.add(card);
      }

      notifyListeners();
    });
    _cardsSubscriptions.add(sub);
  }

  // Select board manually
  void selectBoard(String boardId) {
    final target = _boards.where((b) => b.id == boardId).firstOrNull;
    if (target != null) {
      _activeBoard = target;
      _listenToActiveBoardCards();
      notifyListeners();
    }
  }

  // === BOARD CRUD ===

  Future<void> addBoard(String name, String description, int colorIndex, List<String> columns) async {
    try {
      final board = BoardModel(
        id: '',
        name: name,
        description: description,
        colorIndex: colorIndex,
        columns: columns.isEmpty ? ['Todo', 'In Progress', 'Done'] : columns,
        createdAt: DateTime.now(),
      );
      final id = await _repository.addBoard(board);
      // Automatically switch to the newly created board
      if (id.isNotEmpty) {
        _activeBoard = board.copyWith().copyWith(); // temporary fallback
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBoard(BoardModel board) async {
    try {
      await _repository.updateBoard(board);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBoard(String boardId) async {
    try {
      // 1. Delete all cards under this board
      final cardsToDelete = allCards;
      for (final card in cardsToDelete) {
        await deleteCard(card.id);
      }
      
      // 2. Delete the board itself
      await _repository.deleteBoard(boardId);
      
      // Active board will be updated automatically by the stream listener
    } catch (e) {
      rethrow;
    }
  }

  // === CARD CRUD ===

  Future<void> addCard(KanbanCard card, {bool createLinkedTask = false}) async {
    try {
      final board = _activeBoard;
      if (board == null) return;

      String? taskId;
      if (createLinkedTask && card.dueDate != null) {
        final task = TaskModel(
          id: '',
          title: card.title,
          description: card.description,
          category: card.category ?? 'Pekerjaan',
          priority: card.priority ?? 'Medium',
          dueDate: card.dueDate!,
          completed: card.column == board.columns.last,
          createdAt: DateTime.now(),
        );
        taskId = await _taskRepository.add(task);
      }

      final cardToSave = card.copyWith(
        boardId: board.id,
        taskId: taskId,
      );
      await _repository.add(cardToSave);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCard(KanbanCard card, {bool shouldLinkTask = false}) async {
    try {
      final board = _activeBoard;
      if (board == null) return;

      String? updatedTaskId = card.taskId;

      if (shouldLinkTask && card.dueDate != null) {
        final isCompleted = card.column == board.columns.last;
        if (updatedTaskId == null || updatedTaskId.isEmpty) {
          final task = TaskModel(
            id: '',
            title: card.title,
            description: card.description,
            category: card.category ?? 'Pekerjaan',
            priority: card.priority ?? 'Medium',
            dueDate: card.dueDate!,
            completed: isCompleted,
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
            completed: isCompleted,
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
      
      final board = _activeBoard;
      if (board == null) return;

      final card = allCards.where((c) => c.id == cardId).firstOrNull;
      if (card != null && card.taskId != null && card.taskId!.isNotEmpty) {
        final isCompleted = newColumn == board.columns.last;
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

  // === ANALYTICS & PROGRESS ===

  int getTotalCards() => allCards.length;
  
  int getCompletedCards() {
    final board = _activeBoard;
    if (board == null || board.columns.isEmpty) return 0;
    final lastColumn = board.columns.last;
    return _cardsByColumn[lastColumn]?.length ?? 0;
  }

  double getProgressPercentage() {
    final total = getTotalCards();
    if (total == 0) return 0;
    return (getCompletedCards() / total) * 100;
  }

  @override
  void dispose() {
    _boardsSubscription?.cancel();
    for (final sub in _cardsSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
