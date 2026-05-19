import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';

class VehicleServiceRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('vehicle_services');
  }

  Stream<List<VehicleServiceModel>> watchAll() {
    final col = _col;
    if (col == null) return Stream.value([]);
    return col.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs.map(VehicleServiceModel.fromDoc).toList(),
        );
  }

  Future<List<VehicleServiceModel>> getAll() async {
    final col = _col;
    if (col == null) return [];
    final snapshot = await col.orderBy('date', descending: true).get();
    return snapshot.docs.map(VehicleServiceModel.fromDoc).toList();
  }

  Future<void> add(VehicleServiceModel service) async {
    await _col?.add(service.toMap());
  }

  Future<void> update(VehicleServiceModel service) async {
    final map = service.toMap();
    map.remove('createdAt'); // don't overwrite
    await _col?.doc(service.id).update(map);
  }

  Future<void> delete(String id) async {
    await _col?.doc(id).delete();
  }
}
