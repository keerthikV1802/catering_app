import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:catering_app/models/order.dart';
import 'package:catering_app/models/meal.dart';
import 'package:catering_app/data/orders_repository.dart';
import 'package:catering_app/data/dummy_data.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _refreshOrder() async {
    final updated = await OrdersRepository.instance.getOrderById(_order.id);
    if (updated != null && mounted) {
      setState(() {
        _order = updated;
      });
    }
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newStatus == OrderStatus.accepted ? 'Accept Order?' : 'Delete Order?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          newStatus == OrderStatus.accepted
              ? 'This order will be sent to the chef for preparation.'
              : 'This order will be rejected. This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus == OrderStatus.accepted ? Colors.green : Colors.red,
            ),
            child: Text(newStatus == OrderStatus.accepted ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await OrdersRepository.instance.updateOrderStatus(_order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == OrderStatus.accepted
                  ? 'Order accepted and sent to chef'
                  : 'Order rejected',
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showAddMealsDialog() async {
    final currentMealIds = _order.meals.map((m) => m.id).toSet();
    final availableMeals = dummyMeals
        .where((m) => !currentMealIds.contains(m.id))
        .toList();

    final selectedMeals = await showDialog<List<Meal>>(
      context: context,
      builder: (ctx) => _AddMealsDialog(availableMeals: availableMeals),
    );

    if (selectedMeals != null && selectedMeals.isNotEmpty) {
      await _addMealsToOrder(selectedMeals);
    }
  }

  Future<void> _addMealsToOrder(List<Meal> newMeals) async {
    try {
      await OrdersRepository.instance.addMealsToOrder(_order.id, newMeals);
      await _refreshOrder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newMeals.length} meal(s) added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding meals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeMealFromOrder(Meal meal) async {
    if (_order.meals.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the last meal from order'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Meal?'),
        content: Text('Remove "${meal.title}" from this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await OrdersRepository.instance.removeMealFromOrder(_order.id, meal.id);
        await _refreshOrder();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meal removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing meal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(MealStatus status) {
    switch (status) {
      case MealStatus.notStarted:
        return Colors.grey;
      case MealStatus.preparing:
        return Colors.orange;
      case MealStatus.prepared:
        return Colors.green;
    }
  }

  String _getStatusText(MealStatus status) {
    switch (status) {
      case MealStatus.notStarted:
        return 'Not Started';
      case MealStatus.preparing:
        return 'Preparing';
      case MealStatus.prepared:
        return 'Prepared';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrder,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: _order.status == OrderStatus.accepted
                      ? Colors.green.shade50
                      : _order.status == OrderStatus.rejected
                          ? Colors.red.shade50
                          : Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _order.status == OrderStatus.accepted
                              ? Icons.check_circle
                              : _order.status == OrderStatus.rejected
                                  ? Icons.cancel
                                  : Icons.pending,
                          color: _order.status == OrderStatus.accepted
                              ? Colors.green
                              : _order.status == OrderStatus.rejected
                                  ? Colors.red
                                  : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${_order.status.toString().split('.').last.toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _infoTile('Category', _order.categoryTitle),
                _infoTile(
                  'Date',
                  DateFormat('dd MMM yyyy | hh:mm a').format(_order.functionDate),
                ),
                _infoTile('Guests', _order.guestCount.toString()),
                _infoTile('Venue', _order.venue),
                _infoTile(
                  'Contact',
                  '${_order.contactName} (${_order.contactPhone})',
                ),
                if (_order.managerName.isNotEmpty)
                  _infoTile('Manager', _order.managerName),

                const Divider(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Menu Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        fontSize: 18,
                      ),
                    ),
                    if (_order.status == OrderStatus.pending ||
                        _order.status == OrderStatus.accepted)
                      TextButton.icon(
                        onPressed: _showAddMealsDialog,
                        icon: const Icon(Icons.add_circle, size: 20),
                        label: const Text('Add Meals'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                ..._order.meals.asMap().entries.map((entry) {
                  final meal = entry.value;
                  final progress = _order.mealProgress.firstWhere(
                    (mp) => mp.mealTitle == meal.title,
                    orElse: () => MealProgress(
                      mealId: meal.id,
                      mealTitle: meal.title,
                    ),
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(meal.title),
                      subtitle: Text(
                        '₹${meal.pricePerPlate?.toStringAsFixed(0) ?? '0'} / plate',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(progress.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(progress.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_order.status == OrderStatus.pending)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeMealFromOrder(meal),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                if (_order.customItems.isNotEmpty) ...[
                  const Divider(height: 30),
                  const Text(
                    'Custom Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._order.customItems.map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${c.name} x${c.quantity}'),
                          trailing: Text(
                            '₹${c.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )),
                ],

                const Divider(height: 30),

                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        if (_order.extraCharges > 0)
                          _summaryRow('Extra Charges', _order.extraCharges),
                        if (_order.discount > 0)
                          _summaryRow('Discount', -_order.discount),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${_order.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (_order.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(_order.notes),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_order.status == OrderStatus.pending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(OrderStatus.rejected),
                      icon: const Icon(Icons.cancel),
                      label: const Text('DELETE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus(OrderStatus.accepted),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Dialog for selecting meals to add
class _AddMealsDialog extends StatefulWidget {
  final List<Meal> availableMeals;

  const _AddMealsDialog({required this.availableMeals});

  @override
  State<_AddMealsDialog> createState() => _AddMealsDialogState();
}

class _AddMealsDialogState extends State<_AddMealsDialog> {
  final Set<String> _selectedMealIds = {};

  Future<void> _createCustomMeal() async {
    final result = await showDialog<Meal>(
      context: context,
      builder: (ctx) => const _CreateCustomMealDialog(),
    );

    if (result != null) {
      setState(() {
        widget.availableMeals.add(result);
        _selectedMealIds.add(result.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Meals to Order'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create Custom Meal Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: _createCustomMeal,
                icon: const Icon(Icons.add),
                label: const Text('Create Custom Meal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Available Meals List
            if (widget.availableMeals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No meals available. Create a custom meal!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.availableMeals.length,
                  itemBuilder: (ctx, index) {
                    final meal = widget.availableMeals[index];
                    final isSelected = _selectedMealIds.contains(meal.id);

                    return CheckboxListTile(
                      title: Text(meal.title),
                      subtitle: Text(
                        '₹${meal.pricePerPlate?.toStringAsFixed(0) ?? '0'} / plate',
                      ),
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedMealIds.add(meal.id);
                          } else {
                            _selectedMealIds.remove(meal.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedMealIds.isEmpty
              ? null
              : () {
                  final selectedMeals = widget.availableMeals
                      .where((m) => _selectedMealIds.contains(m.id))
                      .toList();
                  Navigator.pop(context, selectedMeals);
                },
          child: Text('Add ${_selectedMealIds.length} Meal(s)'),
        ),
      ],
    );
  }
}

// Dialog for creating custom meal
class _CreateCustomMealDialog extends StatefulWidget {
  const _CreateCustomMealDialog();

  @override
  State<_CreateCustomMealDialog> createState() => _CreateCustomMealDialogState();
}

class _CreateCustomMealDialogState extends State<_CreateCustomMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '120');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _createMeal() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text) ?? 120.0;

    final meal = Meal(
      id: const Uuid().v4(),
      categories: ['custom'],
      title: _nameController.text.trim(),
      imageUrl: '', // No image for custom meals
      ingredients: [],
      steps: [],
      
      isGlutenFree: false,
      isLactoseFree: false,
      isVegan: false,
      isVegetarian: false,
      pricePerPlate: price,
    );

    Navigator.pop(context, meal);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Meal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createMeal,
          child: const Text('Create'),
        ),
      ],
    );
  }
}