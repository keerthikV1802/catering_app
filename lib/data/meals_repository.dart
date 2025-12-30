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
      await PlatesRepository.instance.addMealToPlate(plateId, meal.id);
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
          await PlatesRepository.instance.removeMealFromPlate(oldPlateId, meal.id);
        }
      }
    }

    await _db.collection(_collection).doc(meal.id).update(meal.toMap());

    // Add to newly selected plates
    for (final plateId in meal.categories) {
      await PlatesRepository.instance.addMealToPlate(plateId, meal.id);
    }
  }

  /// Delete meal
  Future<void> deleteMeal(String mealId) async {
    final doc = await _db.collection(_collection).doc(mealId).get();
    if (doc.exists) {
      final meal = Meal.fromMap(doc.data()!);
      // Remove from all plates
      for (final plateId in meal.categories) {
        await PlatesRepository.instance.removeMealFromPlate(plateId, mealId);
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
}