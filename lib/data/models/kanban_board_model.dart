import 'package:cloud_firestore/cloud_firestore.dart';

const kKanbanColumns = [
  'Todo',
  'In Progress',
  'Review',
  'Done',
];

class KanbanCard {
  final String id;
  final String title;
  final String description;
  final String column; // Todo, In Progress, Review, Done
  final int order;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? taskId;
  final DateTime? dueDate;
  final String? category;
  final String? priority;

  KanbanCard({
    required this.id,
    required this.title,
    required this.description,
    required this.column,
    required this.order,
    required this.createdAt,
    this.updatedAt,
    this.taskId,
    this.dueDate,
    this.category,
    this.priority,
  });

  factory KanbanCard.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KanbanCard(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      column: data['column'] as String? ?? 'Todo',
      order: data['order'] as int? ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      taskId: data['taskId'] as String?,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      category: data['category'] as String?,
      priority: data['priority'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'column': column,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'taskId': taskId,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'category': category,
        'priority': priority,
      };

  KanbanCard copyWith({
    String? title,
    String? description,
    String? column,
    int? order,
    String? taskId,
    DateTime? dueDate,
    String? category,
    String? priority,
  }) {
    return KanbanCard(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      column: column ?? this.column,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      taskId: taskId ?? this.taskId,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
    );
  }
}
