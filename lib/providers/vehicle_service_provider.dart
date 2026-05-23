import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:productivity/core/utils/image_helper.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';
import 'package:productivity/data/repositories/vehicle_service_repository.dart';

class VehicleServiceProvider extends ChangeNotifier {
  final _repository = VehicleServiceRepository();
  StreamSubscription? _subscription;

  List<VehicleServiceModel> _services = [];
  List<VehicleServiceModel> get services => _services;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void initialize() {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.watchAll().listen((data) {
      _services = data;
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addService(VehicleServiceModel service, {File? imageFile}) async {
    VehicleServiceModel serviceToSave = service;
    if (imageFile != null) {
      final base64String = await ImageHelper.fileToBase64(imageFile);
      serviceToSave = service.copyWith(imageUrl: base64String);
    }
    await _repository.add(serviceToSave);
  }

  Future<void> updateService(VehicleServiceModel service, {File? imageFile, bool deleteImage = false}) async {
    VehicleServiceModel serviceToSave = service;
    if (deleteImage) {
      serviceToSave = service.copyWith(imageUrl: ''); // clear image
    } else if (imageFile != null) {
      final base64String = await ImageHelper.fileToBase64(imageFile);
      serviceToSave = service.copyWith(imageUrl: base64String);
    }
    await _repository.update(serviceToSave);
  }

  Future<void> deleteService(String id) async {
    await _repository.delete(id);
  }

  // Get total expense on services
  double getTotalExpense() {
    return _services.fold(0, (sum, item) => sum + item.cost);
  }

  // Check if any service is due soon (e.g., within 7 days or odometer difference)
  List<VehicleServiceModel> getUpcomingServices({int currentOdometer = 0}) {
    final now = DateTime.now();
    return _services.where((s) {
      if (s.nextServiceDate != null) {
        final diffDays = s.nextServiceDate!.difference(now).inDays;
        if (diffDays >= 0 && diffDays <= 7) return true; // Due within 7 days
      }
      if (s.nextServiceOdometer != null && currentOdometer > 0) {
        final diffKm = s.nextServiceOdometer! - currentOdometer;
        if (diffKm >= 0 && diffKm <= 500) return true; // Due within 500 km
      }
      return false;
    }).toList();
  }
}
