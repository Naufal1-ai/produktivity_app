import 'package:cloud_firestore/cloud_firestore.dart';

const kHabitFrequencies = [
  'Daily',
  'Weekly',
  'Monthly',
];

const kHabitCategories = [
  'Health',
  'Productivity',
  'Learning',
  'Social',
  'Finance',
  'Other',
];

class Habit {
  final String id;
  final String name;
  final String description;
  final String category;
  final String frequency; // Daily, Weekly, Monthly
  final int goal; // number of times per week/month
  final DateTime startDate;
  final bool isActive;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.frequency,
    required this.goal,
    required this.startDate,
    required this.isActive,
    required this.createdAt,
  });

  factory Habit.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Habit(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      frequency: data['frequency'] as String? ?? 'Daily',
      goal: data['goal'] as int? ?? 1,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'frequency': frequency,
        'goal': goal,
        'startDate': Timestamp.fromDate(startDate),
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Habit copyWith({
    String? name,
    String? description,
    String? category,
    String? frequency,
    int? goal,
    DateTime? startDate,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      goal: goal ?? this.goal,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final int completedTimes; // how many times completed on this date
  final DateTime createdAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completedTimes,
    required this.createdAt,
  });

  factory HabitLog.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HabitLog(
      id: doc.id,
      habitId: data['habitId'] as String? ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      completedTimes: data['completedTimes'] as int? ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'habitId': habitId,
        'date': Timestamp.fromDate(date),
        'completedTimes': completedTimes,
        'createdAt': FieldValue.serverTimestamp(),
      };

  HabitLog copyWith({
    int? completedTimes,
  }) {
    return HabitLog(
      id: id,
      habitId: habitId,
      date: date,
      completedTimes: completedTimes ?? this.completedTimes,
      createdAt: createdAt,
    );
  }
}

class HabitStats {
  final int totalHabits;
  final int activeHabits;
  final int completedToday;
  final int streak; // current streak in days
  final double completionRate; // percentage

  HabitStats({
    required this.totalHabits,
    required this.activeHabits,
    required this.completedToday,
    required this.streak,
    required this.completionRate,
  });
}
