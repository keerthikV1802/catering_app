import 'package:cloud_firestore/cloud_firestore.dart';
import 'meal.dart';

/// 📊 ORDER STATUS
enum OrderStatus { 
  pending,      // Just placed, awaiting review
  accepted,     // Accepted by manager, sent to chef
  rejected,     // Rejected by manager
  inProgress,   // Chef is preparing
  completed     // All meals prepared
}

/// 🍽️ MEAL STATUS
enum MealStatus { 
  notStarted,   // Not yet started
  preparing,    // Currently being prepared
  prepared      // Completed
}

/// 📋 MEAL PROGRESS TRACKER
class MealProgress {
  final String mealId;
  final String mealTitle;
  MealStatus status;

  MealProgress({
    required this.mealId,
    required this.mealTitle,
    this.status = MealStatus.notStarted,
  });

  Map<String, dynamic> toMap() => {
        'mealId': mealId,
        'mealTitle': mealTitle,
        'status': status.name, // Use .name for cleaner serialization
      };

  factory MealProgress.fromMap(Map<String, dynamic> map) {
    return MealProgress(
      mealId: map['mealId'] ?? '',
      mealTitle: map['mealTitle'] ?? '',
      status: MealStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MealStatus.notStarted,
      ),
    );
  }

  MealProgress copyWith({MealStatus? status}) {
    return MealProgress(
      mealId: mealId,
      mealTitle: mealTitle,
      status: status ?? this.status,
    );
  }
}

/// 🧾 CUSTOM ITEM
class CustomItem {
  final String name;
  final int quantity;
  final double pricePerPlate;

  CustomItem({
    required this.name,
    required this.quantity,
    required this.pricePerPlate,
  });

  double get total => quantity * pricePerPlate;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'pricePerPlate': pricePerPlate,
      };

  factory CustomItem.fromMap(Map<String, dynamic> map) {
    return CustomItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      pricePerPlate: (map['pricePerPlate'] ?? 0).toDouble(),
    );
  }
}

/// 📦 ORDER
class Order {
  final String id;
  final String categoryTitle;
  final DateTime functionDate;
  final String venue;
  final int guestCount;
  final String contactName;
  final String contactPhone;
  final String notes;
  final String managerName;
  final double budget;

  final double totalAmount;
  final double extraCharges;
  final double discount;
  final double finalAmount;

  final DateTime createdAt;
  final List<Meal> meals;
  final List<CustomItem> customItems;
  
  // NEW FIELDS
  final OrderStatus status;
  final List<MealProgress> mealProgress;

  Order({
    required this.id,
    required this.categoryTitle,
    required this.functionDate,
    required this.venue,
    required this.guestCount,
    required this.contactName,
    required this.contactPhone,
    required this.notes,
    this.managerName = '',
    required this.budget,
    required this.totalAmount,
    this.extraCharges = 0,
    this.discount = 0,
    double? finalAmount,
    required this.createdAt,
    required this.meals,
    required this.customItems,
    this.status = OrderStatus.pending,
    List<MealProgress>? mealProgress,
  }) : 
    finalAmount = finalAmount ?? (totalAmount + extraCharges - discount),
    mealProgress = mealProgress ?? _initializeMealProgress(meals);

  // Helper to initialize meal progress from meals
  static List<MealProgress> _initializeMealProgress(List<Meal> meals) {
    return meals.map((meal) => MealProgress(
      mealId: meal.id,
      mealTitle: meal.title,
      status: MealStatus.notStarted,
    )).toList();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryTitle': categoryTitle,
      'functionDate': Timestamp.fromDate(functionDate),
      'venue': venue,
      'guestCount': guestCount,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'notes': notes,
      'managerName': managerName,
      'budget': budget,
      'totalAmount': totalAmount,
      'extraCharges': extraCharges,
      'discount': discount,
      'finalAmount': finalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'meals': meals.map((m) => m.toMap()).toList(),
      'customItems': customItems.map((c) => c.toMap()).toList(),
      'status': status.name,
      'mealProgress': mealProgress.map((mp) => mp.toMap()).toList(),
    };
  }

  factory Order.fromFirestore(String id, Map<String, dynamic> data) {
    final meals = (data['meals'] as List?)
        ?.map((e) => Meal.fromMap(e))
        .toList() ?? [];

    // Load meal progress if exists, otherwise initialize from meals
    List<MealProgress> loadedProgress;
    if (data['mealProgress'] != null) {
      loadedProgress = (data['mealProgress'] as List)
          .map((e) => MealProgress.fromMap(e))
          .toList();
    } else {
      // For existing orders without mealProgress, create it
      loadedProgress = _initializeMealProgress(meals);
    }

    return Order(
      id: id,
      categoryTitle: data['categoryTitle'] ?? '',
      functionDate: (data['functionDate'] as Timestamp).toDate(),
      venue: data['venue'] ?? '',
      guestCount: data['guestCount'] ?? 0,
      contactName: data['contactName'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      notes: data['notes'] ?? '',
      managerName: data['managerName'] ?? '',
      budget: (data['budget'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      extraCharges: (data['extraCharges'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      finalAmount: (data['finalAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      meals: meals,
      customItems: (data['customItems'] as List?)
          ?.map((e) => CustomItem.fromMap(e))
          .toList() ?? [],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      mealProgress: loadedProgress,
    );
  }

  // Helper methods
  bool get isCompleted => 
    mealProgress.isNotEmpty && 
    mealProgress.every((mp) => mp.status == MealStatus.prepared);

  int get completedMealsCount => 
    mealProgress.where((mp) => mp.status == MealStatus.prepared).length;

  double get completionPercentage => 
    mealProgress.isEmpty ? 0 : (completedMealsCount / mealProgress.length);

  Order copyWith({
    OrderStatus? status,
    List<MealProgress>? mealProgress,
  }) {
    return Order(
      id: id,
      categoryTitle: categoryTitle,
      functionDate: functionDate,
      venue: venue,
      guestCount: guestCount,
      contactName: contactName,
      contactPhone: contactPhone,
      notes: notes,
      managerName: managerName,
      budget: budget,
      totalAmount: totalAmount,
      extraCharges: extraCharges,
      discount: discount,
      finalAmount: finalAmount,
      createdAt: createdAt,
      meals: meals,
      customItems: customItems,
      status: status ?? this.status,
      mealProgress: mealProgress ?? this.mealProgress,
    );
  }
}