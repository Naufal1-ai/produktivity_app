import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleServiceModel {
  final String id;
  final String title;
  final String notes;
  final DateTime date;
  final double cost;
  final int odometer;
  final DateTime? nextServiceDate;
  final int? nextServiceOdometer;
  final DateTime createdAt;
  final String? imageUrl;

  VehicleServiceModel({
    required this.id,
    required this.title,
    required this.notes,
    required this.date,
    required this.cost,
    required this.odometer,
    this.nextServiceDate,
    this.nextServiceOdometer,
    required this.createdAt,
    this.imageUrl,
  });

  factory VehicleServiceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleServiceModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      odometer: (data['odometer'] as num?)?.toInt() ?? 0,
      nextServiceDate: data['nextServiceDate'] != null
          ? (data['nextServiceDate'] as Timestamp).toDate()
          : null,
      nextServiceOdometer: (data['nextServiceOdometer'] as num?)?.toInt(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'notes': notes,
        'date': Timestamp.fromDate(date),
        'cost': cost,
        'odometer': odometer,
        'nextServiceDate':
            nextServiceDate != null ? Timestamp.fromDate(nextServiceDate!) : null,
        'nextServiceOdometer': nextServiceOdometer,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      };

  VehicleServiceModel copyWith({
    String? title,
    String? notes,
    DateTime? date,
    double? cost,
    int? odometer,
    DateTime? nextServiceDate,
    int? nextServiceOdometer,
    String? imageUrl,
  }) =>
      VehicleServiceModel(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        cost: cost ?? this.cost,
        odometer: odometer ?? this.odometer,
        nextServiceDate: nextServiceDate ?? this.nextServiceDate,
        nextServiceOdometer: nextServiceOdometer ?? this.nextServiceOdometer,
        createdAt: createdAt,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}
