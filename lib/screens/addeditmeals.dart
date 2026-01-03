import 'package:catering_app/models/meal.dart';
import 'package:catering_app/data/plates_repository.dart';
import 'package:catering_app/models/plate.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/data/meals_repository.dart';

class AddEditMealScreen extends StatefulWidget {
  final Meal? meal;

  const AddEditMealScreen({super.key, this.meal});

  @override
  State<AddEditMealScreen> createState() => _AddEditMealScreenState();
}

class _AddEditMealScreenState extends State<AddEditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isGlutenFree = false;
  bool _isLactoseFree = false;
  bool _isVegetarian = false;
  bool _isVegan = false;
  
  // NEW: Track selected categories
  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    if (widget.meal != null) {
      _titleController.text = widget.meal!.title;
      _imageUrlController.text = widget.meal!.imageUrl;
      _priceController.text = widget.meal!.pricePerPlate.toString();
      _isGlutenFree = widget.meal!.isGlutenFree;
      _isLactoseFree = widget.meal!.isLactoseFree;
      _isVegetarian = widget.meal!.isVegetarian;
      _isVegan = widget.meal!.isVegan;
      _selectedCategories = Set.from(widget.meal!.categories);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one category is selected
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final meal = Meal(
      id: widget.meal?.id ?? const Uuid().v4(),
      categories: _selectedCategories.toList(), // Use selected categories
      title: _titleController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      ingredients: widget.meal?.ingredients ?? [],
      steps: widget.meal?.steps ?? [],
      
      isGlutenFree: _isGlutenFree,
      isLactoseFree: _isLactoseFree,
      isVegan: _isVegan,
      isVegetarian: _isVegetarian,
      pricePerPlate: double.tryParse(_priceController.text) ?? 0,
    );

    try {
      if (widget.meal == null) {
        print('ðŸ”µ Adding meal: ${meal.id} - ${meal.title} to categories: ${meal.categories}');
        await MealsRepository.instance.addMeal(meal);
        print('Rs. œ… Meal added successfully');
      } else {
        print('ðŸ”µ Updating meal: ${meal.id} - ${meal.title}');
        await MealsRepository.instance.updateMeal(meal);
        print('Rs. œ… Meal updated successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.meal == null
                  ? 'Meal added successfully'
                  : 'Meal updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Rs. Œ Error saving meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal == null ? 'Add Meal' : 'Edit Meal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Meal Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Plate *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final price = double.tryParse(v);
                if (price == null || price <= 0) return 'Invalid price';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
                hintText: 'https://example.com/image.jpg',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // NEW: Category Selection
            const Text(
              'Categories *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Plate>>(
              stream: PlatesRepository.instance.watchPlates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final availablePlates = snapshot.data ?? [];
                
                return Card(
                  child: Column(
                    children: availablePlates.map((plate) {
                      return CheckboxListTile(
                        title: Text(plate.title),
                        value: _selectedCategories.contains(plate.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedCategories.add(plate.id);
                            } else {
                              _selectedCategories.remove(plate.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            if (_selectedCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one category',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),

            const Text(
              'Dietary Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Gluten Free'),
              value: _isGlutenFree,
              onChanged: (val) => setState(() => _isGlutenFree = val),
            ),
            SwitchListTile(
              title: const Text('Lactose Free'),
              value: _isLactoseFree,
              onChanged: (val) => setState(() => _isLactoseFree = val),
            ),
            SwitchListTile(
              title: const Text('Vegetarian'),
              value: _isVegetarian,
              onChanged: (val) => setState(() => _isVegetarian = val),
            ),
            SwitchListTile(
              title: const Text('Vegan'),
              value: _isVegan,
              onChanged: (val) => setState(() => _isVegan = val),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saveMeal,
              icon: const Icon(Icons.save),
              label: Text(widget.meal == null ? 'Add Meal' : 'Update Meal'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}