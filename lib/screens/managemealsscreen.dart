import 'package:catering_app/screens/addeditmeals.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/data/meals_repository.dart';
class ManageMealsScreen extends StatefulWidget {
  static const routeName = '/manage-meals';

  const ManageMealsScreen({super.key});

  @override
  State<ManageMealsScreen> createState() => _ManageMealsScreenState();
}

class _ManageMealsScreenState extends State<ManageMealsScreen> {
  List<Meal> _meals = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await MealsRepository.instance.getAllMeals();
      setState(() {
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meals: $e')),
        );
      }
    }
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Meal?'),
        content: Text('Are you sure you want to delete "${meal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MealsRepository.instance.deleteMeal(meal.id);
        await _loadMeals();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meal deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting meal: $e')),
          );
        }
      }
    }
  }

  void _addOrEditMeal([Meal? meal]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddEditMealScreen(meal: meal),
      ),
    );

    if (result == true) {
      _loadMeals();
    }
  }

  List<Meal> get _filteredMeals {
    if (_searchQuery.isEmpty) return _meals;
    return _meals.where((meal) =>
      meal.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeals,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search meals',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMeals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu,
                                size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No meals yet'
                                  : 'No meals found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isEmpty)
                              const Text(
                                'Tap + to create your first meal',
                                style: TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMeals,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMeals.length,
                          itemBuilder: (ctx, index) {
                            final meal = _filteredMeals[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: meal.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          meal.imageUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, error, stack) =>
                                              Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade300,
                                            child: const Icon(Icons.restaurant),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.restaurant),
                                      ),
                                title: Text(
                                  meal.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Rs. ${meal.pricePerPlate.toStringAsFixed(0)} / plate',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _addOrEditMeal(meal),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteMeal(meal),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditMeal(),
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }
}
