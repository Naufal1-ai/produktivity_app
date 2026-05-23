import 'dart:async';
import 'package:flutter/material.dart';
import 'package:productivity/data/models/habit_model.dart';
import 'package:productivity/data/repositories/habit_repository.dart';

class HabitTrackerProvider extends ChangeNotifier {
  final _repository = HabitRepository();
  StreamSubscription? _subscription;
  bool _initialized = false;

  List<Habit> _habits = [];
  final Map<String, List<HabitLog>> _logsCache = {};
  HabitStats? _stats;

  List<Habit> get habits => _habits;
  HabitStats? get stats => _stats;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _subscription?.cancel();
    _subscription = _repository.watchAll().listen((habits) {
      _habits = habits;
      notifyListeners();
    });
    _loadStats();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    _stats = await _repository.getStats();
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _repository.addHabit(habit);
      _loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _repository.updateHabit(habit);
      _loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      _logsCache.remove(habitId);
      _loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logHabitCompletion(String habitId) async {
    try {
      _habits.firstWhere((h) => h.id == habitId); // Validate habit exists
      final today = DateTime.now();

      final log = HabitLog(
        id: '',
        habitId: habitId,
        date: today,
        completedTimes: 1,
        createdAt: today,
      );

      await _repository.logHabitCompletion(log);
      _clearLogCache(habitId);
      _loadStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    if (_logsCache.containsKey(habitId)) {
      return _logsCache[habitId]!;
    }

    // This will be populated through the stream
    return [];
  }

  void _clearLogCache(String habitId) {
    _logsCache.remove(habitId);
  }

  Stream<List<HabitLog>> watchLogsForHabit(String habitId) {
    return _repository.watchLogsForHabit(habitId).map((logs) {
      _logsCache[habitId] = logs;
      return logs;
    });
  }

  Stream<List<HabitLog>> watchLogsForDate(DateTime date) {
    return _repository.watchLogsForDate(date);
  }

  bool isHabitCompletedToday(String habitId) {
    if (!_logsCache.containsKey(habitId)) return false;

    final today = DateTime.now();
    return _logsCache[habitId]!.any((log) {
      return log.date.year == today.year &&
          log.date.month == today.month &&
          log.date.day == today.day;
    });
  }

  int getCompletedHabitsToday() {
    if (_stats == null) return 0;
    return _stats!.completedToday;
  }

  int getStreak() {
    if (_stats == null) return 0;
    return _stats!.streak;
  }

  List<Habit> getHabitsByCategory(String category) {
    return _habits.where((h) => h.category == category).toList();
  }

  Future<void> toggleHabitActive(String habitId, bool isActive) async {
    try {
      final habit = _habits.firstWhere((h) => h.id == habitId);
      await _repository.updateHabit(habit.copyWith(isActive: isActive));
      _loadStats();
    } catch (e) {
      rethrow;
    }
  }
}
