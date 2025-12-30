import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:catering_app/models/order.dart' as app_order;
import 'package:catering_app/models/meal.dart';

class OrdersRepository {
  OrdersRepository._();
  static final instance = OrdersRepository._();

  final _db = FirebaseFirestore.instance;
  final _collection = 'orders';

  /// Add new order
  Future<void> addOrder(app_order.Order order) async {
    await _db.collection(_collection).doc(order.id).set(order.toFirestore());
  }

  /// Watch all orders (real-time)
  Stream<List<app_order.Order>> watchOrders() {
    return _db
        .collection(_collection)
        .orderBy('functionDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Get all orders (one-time fetch)
  Future<List<app_order.Order>> getAllOrders() async {
    final snapshot = await _db
        .collection(_collection)
        .orderBy('functionDate')
        .get();
    
    return snapshot.docs
        .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Update meal price and recalculate total
  Future<void> updateMealPriceAndTotal(
    String orderId,
    List<Meal> updatedMeals,
    double newTotalAmount,
  ) async {
    await _db.collection(_collection).doc(orderId).update({
      'meals': updatedMeals.map((m) => m.toMap()).toList(),
      'totalAmount': newTotalAmount,
      'finalAmount': newTotalAmount,
    });
  }

  /// Get single order by ID
  Future<app_order.Order?> getOrderById(String orderId) async {
    final doc = await _db.collection(_collection).doc(orderId).get();
    
    if (!doc.exists) return null;
    return app_order.Order.fromFirestore(doc.id, doc.data()!);
  }

  /// Get orders for specific date
  Future<List<app_order.Order>> getOrdersForDate(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snap = await _db
        .collection(_collection)
        .where('functionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('functionDate', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Update order status (pending -> accepted/rejected)
  Future<void> updateOrderStatus(
    String orderId, 
    app_order.OrderStatus newStatus,
  ) async {
    await _db.collection(_collection).doc(orderId).update({
      'status': newStatus.name,
    });

    // If all meals are prepared, automatically mark as completed
    if (newStatus == app_order.OrderStatus.accepted) {
      // Check if order should be marked as inProgress
      final order = await getOrderById(orderId);
      if (order != null && order.mealProgress.any(
        (mp) => mp.status != app_order.MealStatus.notStarted
      )) {
        await _db.collection(_collection).doc(orderId).update({
          'status': app_order.OrderStatus.inProgress.name,
        });
      }
    }
  }

  /// Update individual meal status
  Future<void> updateMealStatus(
    String orderId,
    String mealId,
    app_order.MealStatus newStatus,
  ) async {
    // Get current order
    final order = await getOrderById(orderId);
    if (order == null) return;

    // Update the specific meal's status
    final updatedProgress = order.mealProgress.map((mp) {
      if (mp.mealId == mealId) {
        return mp.copyWith(status: newStatus);
      }
      return mp;
    }).toList();

    // Determine order status based on meal progress
    app_order.OrderStatus orderStatus = order.status;
    
    final anyInProgress = updatedProgress.any(
      (mp) => mp.status == app_order.MealStatus.preparing
    );
    final allCompleted = updatedProgress.every(
      (mp) => mp.status == app_order.MealStatus.prepared
    );

    if (allCompleted) {
      orderStatus = app_order.OrderStatus.completed;
    } else if (anyInProgress || updatedProgress.any(
      (mp) => mp.status == app_order.MealStatus.prepared
    )) {
      orderStatus = app_order.OrderStatus.inProgress;
    }

    // Update Firestore
    await _db.collection(_collection).doc(orderId).update({
      'mealProgress': updatedProgress.map((mp) => mp.toMap()).toList(),
      'status': orderStatus.name,
    });
  }

  /// Get orders by status
  Future<List<app_order.Order>> getOrdersByStatus(
    app_order.OrderStatus status,
  ) async {
    final snapshot = await _db
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('functionDate')
        .get();
    
    return snapshot.docs
        .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Get accepted and in-progress orders (for chef)
  Future<List<app_order.Order>> getChefOrders() async {
    final snapshot = await _db
        .collection(_collection)
        .where('status', whereIn: [
          app_order.OrderStatus.accepted.name,
          app_order.OrderStatus.inProgress.name,
        ])
        .orderBy('functionDate')
        .get();
    
    return snapshot.docs
        .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Watch chef orders (real-time)
  Stream<List<app_order.Order>> watchChefOrders() {
    return _db
        .collection(_collection)
        .where('status', whereIn: [
          app_order.OrderStatus.accepted.name,
          app_order.OrderStatus.inProgress.name,
        ])
        .orderBy('functionDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    await _db.collection(_collection).doc(orderId).delete();
  }

  /// Update entire order
  Future<void> updateOrder(app_order.Order order) async {
    await _db.collection(_collection).doc(order.id).update(order.toFirestore());
  }

  /// Get orders count by status
  Future<Map<app_order.OrderStatus, int>> getOrdersCountByStatus() async {
    final orders = await getAllOrders();
    final Map<app_order.OrderStatus, int> counts = {};
    
    for (var status in app_order.OrderStatus.values) {
      counts[status] = orders.where((o) => o.status == status).length;
    }
    
    return counts;
  }

  /// Get upcoming orders (within next 7 days)
  Future<List<app_order.Order>> getUpcomingOrders() async {
    final now = DateTime.now();
    final weekLater = now.add(const Duration(days: 7));

    final snapshot = await _db
        .collection(_collection)
        .where('functionDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('functionDate',
            isLessThanOrEqualTo: Timestamp.fromDate(weekLater))
        .orderBy('functionDate')
        .get();

    return snapshot.docs
        .map((d) => app_order.Order.fromFirestore(d.id, d.data()))
        .toList();
  }

  // ============================================
  // MEAL MANAGEMENT METHODS
  // ============================================

  /// Add meals to existing order
  Future<void> addMealsToOrder(String orderId, List<Meal> newMeals) async {
    final order = await getOrderById(orderId);
    if (order == null) throw Exception('Order not found');

    // Combine existing and new meals
    final updatedMeals = [...order.meals, ...newMeals];

    // Create meal progress for new meals
    final newMealProgress = newMeals.map((meal) => app_order.MealProgress(
      mealId: meal.id,
      mealTitle: meal.title,
      status: app_order.MealStatus.notStarted,
    )).toList();

    final updatedMealProgress = [...order.mealProgress, ...newMealProgress];

    // Calculate new total
    final mealsTotal = updatedMeals.fold<double>(
      0.0,
      (sum, meal) => sum + (meal.pricePerPlate),
    ) * order.guestCount;

    final customTotal = order.customItems.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    final newTotalAmount = mealsTotal + customTotal + order.extraCharges - order.discount;

    // Update Firestore
    await _db.collection(_collection).doc(orderId).update({
      'meals': updatedMeals.map((m) => m.toMap()).toList(),
      'mealProgress': updatedMealProgress.map((mp) => mp.toMap()).toList(),
      'totalAmount': newTotalAmount,
      'finalAmount': newTotalAmount,
    });
  }

  /// Remove meal from order
  Future<void> removeMealFromOrder(String orderId, String mealId) async {
    final order = await getOrderById(orderId);
    if (order == null) throw Exception('Order not found');

    // Cannot remove if only one meal left
    if (order.meals.length <= 1) {
      throw Exception('Cannot remove the last meal from order');
    }

    // Remove the meal
    final updatedMeals = order.meals.where((m) => m.id != mealId).toList();

    // Remove meal progress
    final updatedMealProgress = order.mealProgress
        .where((mp) => mp.mealId != mealId)
        .toList();

    // Recalculate total
    final mealsTotal = updatedMeals.fold<double>(
      0.0,
      (sum, meal) => sum + (meal.pricePerPlate),
    ) * order.guestCount;

    final customTotal = order.customItems.fold<double>(
      0.0,
      (sum, item) => sum + item.total,
    );

    final newTotalAmount = mealsTotal + customTotal + order.extraCharges - order.discount;

    // Update Firestore
    await _db.collection(_collection).doc(orderId).update({
      'meals': updatedMeals.map((m) => m.toMap()).toList(),
      'mealProgress': updatedMealProgress.map((mp) => mp.toMap()).toList(),
      'totalAmount': newTotalAmount,
      'finalAmount': newTotalAmount,
    });
  }
}