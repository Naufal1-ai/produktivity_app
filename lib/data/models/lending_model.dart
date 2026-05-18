import 'package:cloud_firestore/cloud_firestore.dart';

class LendingModel {
  final String id;
  final String itemName;
  final String borrowerName;
  final DateTime borrowDate;
  final DateTime targetReturnDate;
  final bool isReturned;
  final String category;
  final String note;

  LendingModel({
    required this.id,
    required this.itemName,
    required this.borrowerName,
    required this.borrowDate,
    required this.targetReturnDate,
    this.isReturned = false,
    required this.category,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'borrowerName': borrowerName,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'targetReturnDate': Timestamp.fromDate(targetReturnDate),
      'isReturned': isReturned,
      'category': category,
      'note': note,
    };
  }

  factory LendingModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LendingModel(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      borrowerName: data['borrowerName'] ?? '',
      borrowDate:
          (data['borrowDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetReturnDate:
          (data['targetReturnDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReturned: data['isReturned'] ?? false,
      category: data['category'] ?? 'Lainnya',
      note: data['note'] ?? '',
    );
  }
}
