import 'package:cloud_firestore/cloud_firestore.dart';

class PomodoroSession {
  final String id;
  final String taskTitle;
  final int workDuration; // in minutes
  final int breakDuration; // in minutes
  final int completedPomodoros;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final DateTime createdAt;

  PomodoroSession({
    required this.id,
    required this.taskTitle,
    required this.workDuration,
    required this.breakDuration,
    required this.completedPomodoros,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
    required this.createdAt,
  });

  factory PomodoroSession.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PomodoroSession(
      id: doc.id,
      taskTitle: data['taskTitle'] as String? ?? '',
      workDuration: data['workDuration'] as int? ?? 25,
      breakDuration: data['breakDuration'] as int? ?? 5,
      completedPomodoros: data['completedPomodoros'] as int? ?? 0,
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'taskTitle': taskTitle,
        'workDuration': workDuration,
        'breakDuration': breakDuration,
        'completedPomodoros': completedPomodoros,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'isCompleted': isCompleted,
        'createdAt': FieldValue.serverTimestamp(),
      };

  PomodoroSession copyWith({
    String? taskTitle,
    int? workDuration,
    int? breakDuration,
    int? completedPomodoros,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
  }) {
    return PomodoroSession(
      id: id,
      taskTitle: taskTitle ?? this.taskTitle,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

class PomodoroStats {
  final int totalSessions;
  final int totalPomodoros;
  final Duration totalFocusTime;
  final DateTime lastSession;

  PomodoroStats({
    required this.totalSessions,
    required this.totalPomodoros,
    required this.totalFocusTime,
    required this.lastSession,
  });
}
