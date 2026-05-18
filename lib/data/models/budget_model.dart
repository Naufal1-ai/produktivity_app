import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String category;
  final double limit;
  final int month; // 1-12
  final int year;

  BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      category: data['category'] as String,
      limit: (data['limit'] as num).toDouble(),
      month: data['month'] as int,
      year: data['year'] as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'limit': limit,
        'month': month,
        'year': year,
      };

  BudgetModel copyWith({double? limit}) => BudgetModel(
        id: id,
        category: category,
        limit: limit ?? this.limit,
        month: month,
        year: year,
      );
}
