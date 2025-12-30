import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catering_app/models/plate.dart';

class PlatesRepository {
  PlatesRepository._();
  static final instance = PlatesRepository._();

  final _db = FirebaseFirestore.instance;
  final _collection = 'plates';

  /// Watch all plates (real-time)
  Stream<List<Plate>> watchPlates() {
    return _db.collection(_collection).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Plate.fromMap(doc.data())).toList(),
    );
  }

  /// Get all plates
  Future<List<Plate>> getAllPlates() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs.map((doc) => Plate.fromMap(doc.data())).toList();
  }

  /// Add new plate
  Future<void> addPlate(Plate plate) async {
    await _db.collection(_collection).doc(plate.id).set(plate.toMap());
  }

  /// Update plate
  Future<void> updatePlate(Plate plate) async {
    await _db.collection(_collection).doc(plate.id).update(plate.toMap());
  }

  /// Add meal to plate
  Future<void> addMealToPlate(String plateId, String mealId) async {
    await _db.collection(_collection).doc(plateId).update({
      'mealIds': FieldValue.arrayUnion([mealId]),
    });
  }

  /// Remove meal from plate
  Future<void> removeMealFromPlate(String plateId, String mealId) async {
    await _db.collection(_collection).doc(plateId).update({
      'mealIds': FieldValue.arrayRemove([mealId]),
    });
  }
}
