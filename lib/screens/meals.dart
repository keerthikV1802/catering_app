// lib/screens/meals.dart
import 'package:catering_app/screens/OrderPlacementScreen.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/screens/meal_details.dart';
import 'package:catering_app/widgets/meal_item.dart';
import 'package:catering_app/screens/edit_meals_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({
    super.key,
    this.title,
    required this.meals,
    required this.onToggleFavorite,
  });

  final String? title;
  final List<Meal> meals;
  final void Function(Meal meal) onToggleFavorite;

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  late List<Meal> _displayedMeals;

  /// meals added in editor → use ONLY for OrderPlacementScreen
  List<Meal> _addedOnlyMeals = [];

  @override
  void initState() {
    super.initState();
    _displayedMeals = widget.meals.toList();   // original category meals
  }

  void _selectMeal(BuildContext context, Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealDetailsScreen(
          meal: meal,
          onToggleFavorite: widget.onToggleFavorite,
        ),
      ),
    );
  }

  Future<void> _openEditMeals() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (ctx) => EditMealsScreen(
          categoryTitle: widget.title ?? 'Category',
          meals: _displayedMeals,
        ),
      ),
    );

    if (result is Map<String, dynamic>) {
      final updated = result['updatedMeals'] as List<Meal>?;
      final added = result['addedMeals'] as List<Meal>?;

      setState(() {
        if (updated != null) {
          _displayedMeals = updated;   // normal displayed meals
        }
        if (added != null) {
          _addedOnlyMeals = added;     // DO NOT show in UI
        }
      });
    }
  }

  Future<void> _openPlaceOrder() async {
    final orderMeals = [
      ..._displayedMeals,     // show original meals
      ..._addedOnlyMeals,     // include newly added meals for order
    ];

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => OrderPlacementScreen(
          categoryTitle: widget.title ?? 'Category',
          meals: orderMeals,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_displayedMeals.isEmpty) {
      content = Center(
        child: Text(
          "No meals in this category",
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    } else {
      content = ListView.builder(
        itemCount: _displayedMeals.length,
        itemBuilder: (ctx, index) => MealItem(
          meal: _displayedMeals[index],  // ONLY original meals displayed
          onSelectMeal: (meal) => _selectMeal(context, meal),
        ),
      );
    }

    if (widget.title == null) return content;

    return Scaffold(
  appBar: AppBar(
    title: Text(widget.title!),
    actions: [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: _openEditMeals,
      ),
      // ❌ Removed Cart Icon from AppBar
    ],
  ),

  body: content,

  // ✅ Bottom full-width button
  bottomNavigationBar: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text(
            "Place Order",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          onPressed: _openPlaceOrder,
        ),
      ),
    ),
  ),
);

  }
}
