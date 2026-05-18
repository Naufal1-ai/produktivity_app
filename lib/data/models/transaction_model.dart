import 'package:cloud_firestore/cloud_firestore.dart';

const kTransactionCategories = [
  'Gaji',
  'Freelance',
  'Investasi',
  'Bonus',
  'Makan & Minum',
  'Transport',
  'Belanja',
  'Tagihan',
  'Kesehatan',
  'Hiburan',
  'Pendidikan',
  'Lainnya',
];

class TransactionModel {
  final String id;
  final double amount;
  final String type; // 'pemasukan' | 'pengeluaran'
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  bool get isIncome => type == 'pemasukan';

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String,
      category: data['category'] as String? ?? '',
      note: data['note'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      };

  TransactionModel copyWith({
    double? amount,
    String? type,
    String? category,
    String? note,
    DateTime? date,
  }) =>
      TransactionModel(
        id: id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        note: note ?? this.note,
        date: date ?? this.date,
        createdAt: createdAt,
      );
}
