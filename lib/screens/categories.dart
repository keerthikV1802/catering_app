import 'package:flutter/material.dart';
import 'package:catering_app/models/plate.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/data/plates_repository.dart';
import 'package:catering_app/widgets/category_grid_item.dart';
import 'package:catering_app/screens/meals.dart';
import 'package:uuid/uuid.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({
    super.key,
    required this.onToggleFavorite,
    required this.availableMeals,
  });

  final void Function(Meal meal) onToggleFavorite;
  final List<Meal> availableMeals;

  void _selectCategory(BuildContext context, Plate plate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MealsScreen(
          title: plate.title,
          categoryId: plate.id,
          onToggleFavorite: onToggleFavorite,
        ),
      ),
    );
  }

  void _deletePlate(BuildContext context, Plate plate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plate?'),
        content: Text(
            'Are you sure you want to delete "${plate.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await PlatesRepository.instance.deletePlate(plate.id);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  double _computePerPlateForCategory(String categoryId) {
    final meals = availableMeals.where((m) => m.categories.contains(categoryId));
    return meals.fold(0.0, (s, m) => s + m.pricePerPlate);
  }

  void _addPlate(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Plate'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Plate Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isEmpty) return;

              // 1. Check for special characters
              final specialCharRegex = RegExp(r'[!@#%^&*(),.?":{}|<>]');
              if (specialCharRegex.hasMatch(title)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Special characters are not allowed in plate names')),
                  );
                }
                return;
              }

              // 2. Check for duplicate names (case-insensitive)
              try {
                final existingPlates = await PlatesRepository.instance.getAllPlates();
                final isDuplicate = existingPlates.any(
                  (p) => p.title.toLowerCase() == title.toLowerCase()
                );

                if (isDuplicate) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('A plate named "$title" already exists')),
                    );
                  }
                  return;
                }

                final newPlate = Plate(
                  id: const Uuid().v4(),
                  title: title,
                  color: Colors.orange,
                );
                await PlatesRepository.instance.addPlate(newPlate);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                 if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding plate: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Plate>>(
      stream: PlatesRepository.instance.watchPlates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final plates = snapshot.data ?? [];

        return Scaffold(
          body: plates.isEmpty
              ? const Center(child: Text('No categories yet. Add one!'))
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: plates.length,
                  itemBuilder: (ctx, index) {
                    final plate = plates[index];
                    return CategoryGridItem(
                      plate: plate,
                      perPlate: _computePerPlateForCategory(plate.id),
                      onSelectCategory: () {
                        _selectCategory(context, plate);
                      },
                      onDelete: () => _deletePlate(context, plate),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addPlate(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}