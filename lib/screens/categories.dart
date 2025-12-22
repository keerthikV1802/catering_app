// lib/screens/categories.dart
import 'package:flutter/material.dart';
import 'package:catering_app/models/category.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/data/dummy_data.dart';
import 'package:catering_app/widgets/category_grid_item.dart';
import 'package:catering_app/screens/meals.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.onToggleFavorite,
    required this.availableMeals,
  });

  final void Function(Meal meal) onToggleFavorite;
  final List<Meal> availableMeals;

  void _selectCategory(BuildContext context, Category category) {
    final filteredMeals = availableMeals
        .where((meal) => meal.categories.contains(category.id))
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealsScreen(
          title: category.title,
          meals: filteredMeals,
          onToggleFavorite: onToggleFavorite,
        ),
      ),
    );
  }

  double _computePerPlateForCategory(String categoryId) {
    final meals = availableMeals.where((m) => m.categories.contains(categoryId));
    return meals.fold(0.0, (s, m) => s + m.pricePerPlate);
  }

  @override
  Widget build(BuildContext context) {
    return GridView(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      children: [
        for (final category in availableCategories)
          CategoryGridItem(
            category: category,
            perPlate: _computePerPlateForCategory(category.id),
            onSelectCategory: () {
              _selectCategory(context, category);
            },
          )
      ],
    );
  }
}
