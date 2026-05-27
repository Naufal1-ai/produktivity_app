import 'package:cloud_firestore/cloud_firestore.dart';

class BoardModel {
  final String id;
  final String name;
  final String description;
  final int colorIndex; // Indeks untuk tema warna/gradien latar belakang
  final List<String> columns; // Kolom kustom, contoh: ['Todo', 'In Progress', 'Done']
  final DateTime createdAt;
  final DateTime? updatedAt;

  BoardModel({
    required this.id,
    required this.name,
    required this.description,
    required this.colorIndex,
    required this.columns,
    required this.createdAt,
    this.updatedAt,
  });

  factory BoardModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoardModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      colorIndex: data['colorIndex'] as int? ?? 0,
      columns: List<String>.from(data['columns'] as List? ?? ['Todo', 'In Progress', 'Done']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'colorIndex': colorIndex,
        'columns': columns,
        'createdAt': createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  BoardModel copyWith({
    String? name,
    String? description,
    int? colorIndex,
    List<String>? columns,
  }) {
    return BoardModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorIndex: colorIndex ?? this.colorIndex,
      columns: columns ?? this.columns,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
