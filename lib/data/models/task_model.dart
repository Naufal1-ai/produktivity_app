import 'package:cloud_firestore/cloud_firestore.dart';

const kTaskCategories = [
  'Keuangan',
  'Servis Motor',
  'Olahraga',
  'Pekerjaan',
  'Pribadi',
  'Lainnya',
];

const kTaskPriorities = [
  'Low',
  'Medium',
  'High',
];

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final DateTime dueDate;
  final bool completed;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.completed,
    required this.createdAt,
  });

  bool get isOverdue => !completed && dueDate.isBefore(DateTime.now());

  factory TaskModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Lainnya',
      priority: data['priority'] as String? ?? 'Medium',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      completed: data['completed'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'dueDate': Timestamp.fromDate(dueDate),
        'completed': completed,
        'createdAt': FieldValue.serverTimestamp(),
      };

  TaskModel copyWith({
    String? title,
    String? description,
    String? category,
    String? priority,
    DateTime? dueDate,
    bool? completed,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}
