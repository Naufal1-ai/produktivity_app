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

  KanbanCard({
    required this.id,
    required this.title,
    required this.description,
    required this.column,
    required this.order,
    required this.createdAt,
    this.updatedAt,
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
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'column': column,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  KanbanCard copyWith({
    String? title,
    String? description,
    String? column,
    int? order,
  }) {
    return KanbanCard(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      column: column ?? this.column,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
