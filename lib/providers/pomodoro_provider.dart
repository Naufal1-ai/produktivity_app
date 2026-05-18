import 'dart:async';
import 'package:flutter/material.dart';
import 'package:productivity/data/models/pomodoro_model.dart';
import 'package:productivity/data/repositories/pomodoro_repository.dart';

class PomodoroProvider extends ChangeNotifier {
  final _repository = PomodoroRepository();

  List<PomodoroSession> _sessions = [];
  PomodoroStats? _stats;
  PomodoroSession? _currentSession;

  bool _isRunning = false;
  bool _isWorkSession = true;
  int _remainingSeconds = 25 * 60;
  final int _workDuration = 25;
  final int _breakDuration = 5;
  String _currentTask = '';
  Timer? _timer;
  bool _initialized = false;

  List<PomodoroSession> get sessions => _sessions;
  PomodoroStats? get stats => _stats;
  PomodoroSession? get currentSession => _currentSession;
  bool get isRunning => _isRunning;
  bool get isWorkSession => _isWorkSession;
  int get remainingSeconds => _remainingSeconds;
  String get currentTask => _currentTask;
  Duration get remainingDuration => Duration(seconds: _remainingSeconds);
  bool get hasActiveSession => _currentSession != null && _isRunning;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _repository.watchAll().listen((sessions) {
      _sessions = sessions;
      notifyListeners();
    });
    _loadStats();
  }

  Future<void> _loadStats() async {
    _stats = await _repository.getStats();
    notifyListeners();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void startTimer(String taskTitle) {
    if (_isRunning) return;

    if (_currentTask.isEmpty || _currentSession == null) {
      _currentTask = taskTitle;
      _currentSession = PomodoroSession(
        id: '',
        taskTitle: taskTitle,
        workDuration: _workDuration,
        breakDuration: _breakDuration,
        completedPomodoros: 0,
        startTime: DateTime.now(),
        endTime: null,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      _isWorkSession = true;
      _remainingSeconds = _workDuration * 60;
    }

    _startPomodoroTimer();
    notifyListeners();
  }

  void _startPomodoroTimer() {
    _timer?.cancel();
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _isWorkSession = true;
    _remainingSeconds = _workDuration * 60;
    _currentTask = '';
    _currentSession = null;
    notifyListeners();
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _isRunning = false;

    if (_isWorkSession) {
      _completeSession();
      _switchToBreak();
    } else {
      _switchToWork();
    }
  }

  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    final finished = _currentSession!.copyWith(
      completedPomodoros: _currentSession!.completedPomodoros + 1,
      isCompleted: true,
      endTime: DateTime.now(),
    );

    try {
      await _repository.add(finished);
      _currentSession = null;
      _loadStats();
    } catch (_) {
      // Ignore repository failures for timer state.
    }
  }

  void _switchToBreak() {
    _isWorkSession = false;
    _remainingSeconds = _breakDuration * 60;
    _startPomodoroTimer();
    notifyListeners();
  }

  void _switchToWork() {
    _isWorkSession = true;
    _remainingSeconds = _workDuration * 60;
    _startPomodoroTimer();
    notifyListeners();
  }

  int getTodaysSessions() {
    final today = DateTime.now();
    return _sessions.where((s) {
      final sameDay = s.createdAt.year == today.year &&
          s.createdAt.month == today.month &&
          s.createdAt.day == today.day;
      return sameDay && s.isCompleted;
    }).length;
  }

  int getTotalFocusMinutesToday() {
    final today = DateTime.now();
    int total = 0;
    for (final session in _sessions) {
      final sameDay = session.createdAt.year == today.year &&
          session.createdAt.month == today.month &&
          session.createdAt.day == today.day;
      if (sameDay && session.isCompleted) {
        total += session.completedPomodoros * session.workDuration;
      }
    }
    return total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
