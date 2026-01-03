import 'package:catering_app/screens/OrderPlacementScreen.dart';
import 'package:catering_app/screens/managemealsscreen.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/widgets/meal_item.dart';
import 'package:catering_app/data/meals_repository.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({
    super.key,
    this.title,
    this.categoryId, // NEW: Pass category ID instead of meals list
    this.meals, // Keep for favorites screen
    required this.onToggleFavorite,
  });

  final String? title;
  final String? categoryId; // NEW: Category ID for filtering
  final List<Meal>? meals; // Optional: only for favorites
  final void Function(Meal meal) onToggleFavorite;

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  List<Meal> _addedOnlyMeals = [];


  // Navigate to global Manage Meals screen
  Future<void> _openManageMeals() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ManageMealsScreen(plateId: widget.categoryId),
      ),
    );
    // Stream will auto-update, no need to pop
  }

  Future<void> _openPlaceOrder(List<Meal> meals) async {
    final orderMeals = [
      ...meals,
      ..._addedOnlyMeals,
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

  Widget _buildContent(List<Meal> meals) {
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              widget.categoryId != null 
                  ? "No meals in this category"
                  : "No favorite meals yet",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.categoryId != null)
              TextButton.icon(
                onPressed: _openManageMeals,
                icon: const Icon(Icons.add),
                label: const Text('Add Meals'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (ctx, index) => MealItem(
        meal: meals[index],
        onSelectMeal: (meal) {}, // No action needed as details screen is removed
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If this is a favorites screen (no categoryId), use the provided meals list
    if (widget.categoryId == null && widget.meals != null) {
      final content = _buildContent(widget.meals!);
      
      if (widget.title == null) return content;

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title!),
        ),
        body: content,
      );
    }

    // For category screens, use StreamBuilder to watch meals
    return StreamBuilder<List<Meal>>(
      stream: MealsRepository.instance.watchMeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title ?? 'Meals'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.restaurant_menu),
                  tooltip: 'Manage Meals',
                  onPressed: _openManageMeals,
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title ?? 'Meals'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        final allMeals = snapshot.data ?? [];
        
        // Filter meals by category
        final categoryMeals = widget.categoryId != null
            ? allMeals.where((meal) => 
                meal.categories.contains(widget.categoryId)).toList()
            : allMeals;

        final content = _buildContent(categoryMeals);

        if (widget.title == null) return content;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title!),
            actions: [
              IconButton(
                icon: const Icon(Icons.restaurant_menu),
                tooltip: 'Manage Meals',
                onPressed: _openManageMeals,
              ),
            ],
          ),
          body: content,
          bottomNavigationBar: categoryMeals.isEmpty 
            ? null
            : SafeArea(
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
                      onPressed: () => _openPlaceOrder(categoryMeals),
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }
}