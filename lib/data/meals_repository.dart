import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/data/plates_repository.dart';

class MealsRepository {
  MealsRepository._();
  static final instance = MealsRepository._();

  final _db = FirebaseFirestore.instance;
  final _collection = 'meals';

  /// Add new meal
  Future<void> addMeal(Meal meal) async {
    await _db.collection(_collection).doc(meal.id).set(meal.toMap());
    // Sync with plates
    for (final plateId in meal.categories) {
      try {
        await PlatesRepository.instance.addMealToPlate(plateId, meal.id);
      } catch (e) {
        print('Sync error (add meal to plate $plateId during add): $e');
      }
    }
  }

  /// Get all meals
  Future<List<Meal>> getAllMeals() async {
    final snapshot = await _db.collection(_collection).get();
    return snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
  }

  /// Watch all meals (real-time)
  Stream<List<Meal>> watchMeals() {
    return _db.collection(_collection).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList(),
    );
  }

  /// Get meals by category
  Future<List<Meal>> getMealsByCategory(String categoryId) async {
    final snapshot = await _db
        .collection(_collection)
        .where('plates', arrayContains: categoryId)
        .get();
    return snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
  }

  /// Update meal
  Future<void> updateMeal(Meal meal) async {
    // Get old meal to find which plates were removed
    final oldDoc = await _db.collection(_collection).doc(meal.id).get();
    if (oldDoc.exists) {
      final oldMeal = Meal.fromMap(oldDoc.data()!);
      // Remove from plates that are no longer selected
      for (final oldPlateId in oldMeal.categories) {
        if (!meal.categories.contains(oldPlateId)) {
          try {
            await PlatesRepository.instance.removeMealFromPlate(oldPlateId, meal.id);
          } catch (e) {
            print('Sync error (remove meal from plate $oldPlateId): $e');
            // Ignore [not-found] errors for legacy categories
          }
        }
      }
    }

    await _db.collection(_collection).doc(meal.id).set(meal.toMap(), SetOptions(merge: true));

    // Add to newly selected plates
    for (final plateId in meal.categories) {
      try {
        await PlatesRepository.instance.addMealToPlate(plateId, meal.id);
      } catch (e) {
        print('Sync error (add meal to plate $plateId): $e');
        // Ignore [not-found] errors for legacy categories
      }
    }
  }

  /// Delete meal
  Future<void> deleteMeal(String mealId) async {
    final doc = await _db.collection(_collection).doc(mealId).get();
    if (doc.exists) {
      final meal = Meal.fromMap(doc.data()!);
      // Remove from all plates
      for (final plateId in meal.categories) {
        try {
          await PlatesRepository.instance.removeMealFromPlate(plateId, mealId);
        } catch (e) {
          print('Sync error (remove meal from plate $plateId during delete): $e');
        }
      }
    }
    await _db.collection(_collection).doc(mealId).delete();
  }

  /// Search meals by name
  Future<List<Meal>> searchMeals(String query) async {
    final snapshot = await _db.collection(_collection).get();
    final meals = snapshot.docs.map((doc) => Meal.fromMap(doc.data())).toList();
    
    return meals.where((meal) => 
      meal.title.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Specialized method for toggling a plate in a meal without full sync
  Future<void> togglePlateInMeal(String mealId, String plateId, bool isAdding) async {
    final batch = _db.batch();
    
    // Update Meal document
    final mealRef = _db.collection(_collection).doc(mealId);
    batch.update(mealRef, {
      'plates': isAdding 
          ? FieldValue.arrayUnion([plateId]) 
          : FieldValue.arrayRemove([plateId]),
    });

    // Update Plate document
    final plateRef = _db.collection('plates').doc(plateId);
    batch.update(plateRef, {
      'mealIds': isAdding 
          ? FieldValue.arrayUnion([mealId]) 
          : FieldValue.arrayRemove([mealId]),
    });

    await batch.commit();
  }
}