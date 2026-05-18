import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/habit_model.dart';

class HabitRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _habitCol {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('habits');
  }

  CollectionReference? get _logCol {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('habit_logs');
  }

  Stream<List<Habit>> watchAll() {
    final col = _habitCol;
    if (col == null) return Stream.value([]);
    return col
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Habit.fromDoc).toList());
  }

  Stream<List<Habit>> watchByCategory(String category) {
    final col = _habitCol;
    if (col == null) return Stream.value([]);
    return col
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Habit.fromDoc).toList());
  }

  // Habits
  Future<void> addHabit(Habit habit) async {
    await _habitCol?.add(habit.toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    final data = habit.toMap();
    data.remove('createdAt');
    await _habitCol?.doc(habit.id).update(data);
  }

  Future<void> deleteHabit(String id) async {
    await _habitCol?.doc(id).delete();
  }

  // Habit Logs
  Stream<List<HabitLog>> watchLogsForHabit(String habitId) {
    final col = _logCol;
    if (col == null) return Stream.value([]);
    return col
        .where('habitId', isEqualTo: habitId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(HabitLog.fromDoc).toList());
  }

  Stream<List<HabitLog>> watchLogsForDate(DateTime date) {
    final col = _logCol;
    if (col == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) => snap.docs.map(HabitLog.fromDoc).toList());
  }

  Future<void> logHabitCompletion(HabitLog log) async {
    // Check if log already exists for this habit and date
    final query = await _logCol
        ?.where('habitId', isEqualTo: log.habitId)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(log.date.year, log.date.month, log.date.day)),
        )
        .where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(
            DateTime(log.date.year, log.date.month, log.date.day, 23, 59, 59),
          ),
        )
        .get();

    if (query != null && query.docs.isNotEmpty) {
      // Update existing log
      final existingLog = HabitLog.fromDoc(query.docs.first);
      final updated = existingLog.copyWith(
        completedTimes: existingLog.completedTimes + 1,
      );
      await _logCol?.doc(existingLog.id).update(updated.toMap());
    } else {
      // Create new log
      await _logCol?.add(log.toMap());
    }
  }

  Future<void> updateHabitLog(HabitLog log) async {
    final data = log.toMap();
    data.remove('createdAt');
    await _logCol?.doc(log.id).update(data);
  }

  Future<void> deleteHabitLog(String id) async {
    await _logCol?.doc(id).delete();
  }

  Future<HabitStats> getStats() async {
    final habits = await _habitCol?.where('isActive', isEqualTo: true).get();
    if (habits == null || habits.docs.isEmpty) {
      return HabitStats(
        totalHabits: 0,
        activeHabits: 0,
        completedToday: 0,
        streak: 0,
        completionRate: 0,
      );
    }

    final totalHabits = habits.docs.length;

    // Get today's logs
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final todayLogs = await _logCol
        ?.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int completedToday = todayLogs?.docs.length ?? 0;

    // Calculate streak
    int streak = 0;
    DateTime currentDate = today;
    while (true) {
      final dayStart =
          DateTime(currentDate.year, currentDate.month, currentDate.day);
      final dayEnd = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        23,
        59,
        59,
      );

      final dayLogs = await _logCol
          ?.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
          .get();

      if (dayLogs != null && dayLogs.docs.isNotEmpty) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Calculate completion rate
    final allLogs = await _logCol?.get();
    double completionRate = 0;
    if (allLogs != null && allLogs.docs.isNotEmpty) {
      completionRate = (completedToday / totalHabits) * 100;
    }

    return HabitStats(
      totalHabits: totalHabits,
      activeHabits: totalHabits,
      completedToday: completedToday,
      streak: streak,
      completionRate: completionRate,
    );
  }
}
