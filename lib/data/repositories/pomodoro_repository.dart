import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/pomodoro_model.dart';

class PomodoroRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('pomodoro_sessions');
  }

  Stream<List<PomodoroSession>> watchAll() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PomodoroSession.fromDoc).toList());
  }

  Stream<List<PomodoroSession>> watchByDate(DateTime date) {
    final col = _col;
    if (col == null) return Stream.value([]);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return col
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PomodoroSession.fromDoc).toList());
  }

  Future<void> add(PomodoroSession session) async {
    await _col?.add(session.toMap());
  }

  Future<void> update(PomodoroSession session) async {
    final data = session.toMap();
    data.remove('createdAt');
    await _col?.doc(session.id).update(data);
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }

  Future<PomodoroStats> getStats() async {
    final col = _col;
    if (col == null) {
      return PomodoroStats(
        totalSessions: 0,
        totalPomodoros: 0,
        totalFocusTime: Duration.zero,
        lastSession: DateTime.now(),
      );
    }

    final snapshot = await col.get();
    final sessions = snapshot.docs.map(PomodoroSession.fromDoc).toList();

    if (sessions.isEmpty) {
      return PomodoroStats(
        totalSessions: 0,
        totalPomodoros: 0,
        totalFocusTime: Duration.zero,
        lastSession: DateTime.now(),
      );
    }

    int totalPomodoros = 0;
    Duration totalFocusTime = Duration.zero;

    for (final session in sessions) {
      totalPomodoros += session.completedPomodoros;
      totalFocusTime +=
          Duration(minutes: session.completedPomodoros * session.workDuration);
    }

    return PomodoroStats(
      totalSessions: sessions.length,
      totalPomodoros: totalPomodoros,
      totalFocusTime: totalFocusTime,
      lastSession: sessions.first.createdAt,
    );
  }
}
