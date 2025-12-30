// lib/screens/edit_meals_screen.dart
import 'package:flutter/material.dart';
import 'package:catering_app/models/meal.dart';

class EditMealsScreen extends StatefulWidget {
  static const routeName = '/edit-meals';

  final String categoryTitle;
  final List<Meal> meals;

  const EditMealsScreen({
    super.key,
    required this.categoryTitle,
    required this.meals,
  });

  @override
  State<EditMealsScreen> createState() => _EditMealsScreenState();
}

class _EditMealsScreenState extends State<EditMealsScreen> {
  late List<Meal> _editableMeals;

  /// Newly added meals Rs. €“ should NOT appear in MealsScreen
  final List<Meal> _newMeals = [];

  @override
  void initState() {
    super.initState();
    _editableMeals = [...widget.meals];
  }

  void _removeMeal(int index) {
    setState(() => _editableMeals.removeAt(index));
  }

  Future<void> _showAddMealDialog() async {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '120');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add new meal",style: TextStyle(color: Colors.green),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl,style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title",hintStyle: TextStyle(color: Colors.white))),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl,style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Add")),
        ],
      ),
    );

    if (res != true) return;

    final title = titleCtrl.text.trim();
    final price = double.tryParse(priceCtrl.text) ?? 0;

    if (title.isEmpty || price <= 0) return;

    final newMeal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categories: [],
      title: title,
      imageUrl: "", // no network call Rs. †’ no crash
      
      ingredients: const [],
      steps: const [],
      isGlutenFree: false,
      isVegan: false,
      isVegetarian: false,
      isLactoseFree: false,
      pricePerPlate: price,
    );

    setState(() {
      _editableMeals.add(newMeal);
      _newMeals.add(newMeal); // but return separately
    });
  }

  void _saveAndPop() {
    Navigator.of(context).pop({
      'updatedMeals': _editableMeals,
      'addedMeals': _newMeals,
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveAndPop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit: ${widget.categoryTitle}"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _saveAndPop),
        ),
        body: ListView.builder(
          itemCount: _editableMeals.length,
          itemBuilder: (ctx, i) {
            final meal = _editableMeals[i];
            return ListTile(
              title: Text(meal.title),
              subtitle: Text("Rs. ${meal.pricePerPlate.toStringAsFixed(0)} / plate"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeMeal(i),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMealDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
