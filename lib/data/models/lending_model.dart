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
  final String? imageUrl;

  LendingModel({
    required this.id,
    required this.itemName,
    required this.borrowerName,
    required this.borrowDate,
    required this.targetReturnDate,
    this.isReturned = false,
    required this.category,
    this.note = '',
    this.imageUrl,
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
      'imageUrl': imageUrl,
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
      imageUrl: data['imageUrl'] as String?,
    );
  }

  LendingModel copyWith({
    String? itemName,
    String? borrowerName,
    DateTime? borrowDate,
    DateTime? targetReturnDate,
    bool? isReturned,
    String? category,
    String? note,
    String? imageUrl,
  }) {
    return LendingModel(
      id: id,
      itemName: itemName ?? this.itemName,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowDate: borrowDate ?? this.borrowDate,
      targetReturnDate: targetReturnDate ?? this.targetReturnDate,
      isReturned: isReturned ?? this.isReturned,
      category: category ?? this.category,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
