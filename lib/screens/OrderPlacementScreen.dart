import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:catering_app/models/meal.dart';
import 'package:catering_app/models/order.dart' as order_model;
import 'package:catering_app/data/orders_repository.dart';

class OrderPlacementScreen extends StatefulWidget {
  static const routeName = '/place-order';

  final String categoryTitle;
  final List<Meal> meals;
  final List<Meal> extraMeals;

  const OrderPlacementScreen({
    super.key,
    required this.categoryTitle,
    required this.meals,
    this.extraMeals = const [],
  });

  @override
  State<OrderPlacementScreen> createState() => _OrderPlacementScreenState();
}

class _OrderPlacementScreenState extends State<OrderPlacementScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _functionDate;

  final _venueController = TextEditingController();
  final _guestController = TextEditingController(text: '100');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _extraChargesController = TextEditingController(text: '0');
  final _discountController = TextEditingController(text: '0');
  final _perPlateOverrideController = TextEditingController();

  final List<order_model.CustomItem> _customItems = [];

  List<Meal> get _combinedMeals => [...widget.meals, ...widget.extraMeals];

  double _calcTotal() {
    final guests = int.tryParse(_guestController.text) ?? 0;
    final overridePerPlate = double.tryParse(_perPlateOverrideController.text);

    double perPlateTotal;
    if (overridePerPlate != null && overridePerPlate > 0) {
      perPlateTotal = overridePerPlate;
    } else {
      perPlateTotal = _combinedMeals.fold<double>(
        0.0,
        (s, m) => s + (m.pricePerPlate ?? 0),
      );
    }

    final mealsTotal = perPlateTotal * guests;
    final customTotal = _customItems.fold<double>(0.0, (s, c) => s + c.total);
    final extraCharges = double.tryParse(_extraChargesController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    return mealsTotal + customTotal + extraCharges - discount;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (timeOfDay == null) return;

    setState(() {
      _functionDate = DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
    });
  }

  Future<void> _addCustomItemDialog() async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '100');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Item Name'),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity'),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price per Unit'),
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (res == true) {
      final name = nameCtrl.text.trim();
      final qty = int.tryParse(qtyCtrl.text) ?? 0;
      final price = double.tryParse(priceCtrl.text) ?? 0;

      if (name.isEmpty || qty <= 0 || price <= 0) return;

      setState(() {
        _customItems.add(
          order_model.CustomItem(
            name: name,
            quantity: qty,
            pricePerPlate: price,
          ),
        );
      });
    }
  }

  void _removeCustomItem(int index) {
    setState(() {
      _customItems.removeAt(index);
    });
  }

  void _placeOrder() async {
    if (_functionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select function date & time')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final total = _calcTotal();

    final order = order_model.Order(
      id: const Uuid().v4(),
      categoryTitle: widget.categoryTitle,
      functionDate: _functionDate!,
      venue: _venueController.text.trim(),
      guestCount: int.tryParse(_guestController.text) ?? 0,
      contactName: _nameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
      budget: double.tryParse(_budgetController.text) ?? 0,
      meals: _combinedMeals,
      customItems: _customItems,
      totalAmount: total,
      createdAt: DateTime.now(),
      managerName: _managerNameController.text.trim(),
      extraCharges: double.tryParse(_extraChargesController.text) ?? 0,
      discount: double.tryParse(_discountController.text) ?? 0,
    );

    await OrdersRepository.instance.addOrder(order);

    if (!mounted) return;

    await showDialog(
      
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Placed Successfully',style: TextStyle(color: Colors.white),),
        content: Text('Total Amount: ₹${total.toStringAsFixed(0)}',style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
        
      ),
    );

    if (!mounted) return;
Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _venueController.dispose();
    _guestController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    _managerNameController.dispose();
    _extraChargesController.dispose();
    _discountController.dispose();
    _perPlateOverrideController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final computedTotal = _calcTotal();
    final perPlatePrice = _combinedMeals.fold<double>(
      0.0,
      (s, m) => s + (m.pricePerPlate ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Place Order - ${widget.categoryTitle}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            
            // FUNCTION DETAILS SECTION
            _buildSectionHeader('Function Details'),
            Card(color: Colors.blue.shade50,
              child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      title: Text(
                        _functionDate == null
                            ? 'Select Date & Time *'
                            : 'Date: ${_functionDate!.day}/${_functionDate!.month}/${_functionDate!.year} ${_functionDate!.hour}:${_functionDate!.minute.toString().padLeft(2, '0')}',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Pick'),
                      ),
                    ),),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guestController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Guests *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final num = int.tryParse(v);
                        if (num == null || num <= 0) return 'Must be positive';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),

            // CUSTOMER INFORMATION SECTION
            _buildSectionHeader('Customer Information'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 10) return 'Invalid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _managerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Order Taken By (Manager) ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      style: TextStyle(color: Colors.white),
                      
                    ),
                  ],
                ),
              ),
            ),

            // SELECTED MEALS SECTION
            _buildSectionHeader('Selected Meals'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_combinedMeals.isEmpty)
                      const Text('No meals selected',style: TextStyle(color: Colors.white),)
                    else
                      ..._combinedMeals.map((meal) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(meal.title,style: TextStyle(color: Colors.amber),)),
                                Text(
                                  '₹${meal.pricePerPlate?.toStringAsFixed(0) ?? '0'}/plate',
                                  style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.amber),
                                ),
                              ],
                            ),
                          )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Per Plate Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${perPlatePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // CUSTOM ITEMS SECTION
            _buildSectionHeader('Custom Items'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_customItems.isEmpty)
                      const Text('No custom items added',style: TextStyle(color: Colors.white),)
                    else
                      ..._customItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          subtitle: Text('Qty: ${item.quantity} × ₹${item.pricePerPlate}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${item.total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeCustomItem(idx),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addCustomItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Item'),
                    ),
                  ],
                ),
              ),
            ),

            // PRICING SECTION
            _buildSectionHeader('Pricing'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _perPlateOverrideController,
                      decoration: const InputDecoration(
                        labelText: 'Override Per Plate Price (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                        helperText: 'Leave empty to use calculated price',
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Budget (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _extraChargesController,
                      decoration: const InputDecoration(
                        labelText: 'Extra Charges',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.add_circle_outline),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.discount),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),

            // NOTES SECTION
            _buildSectionHeader('Additional Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Special Instructions',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  style: TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // FINAL TOTAL
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Final Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${computedTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // PLACE ORDER BUTTON
            ElevatedButton(
              onPressed: _placeOrder,
              
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                
              ),
              
              child: const Text(
                'Place Order',
                style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 255, 255, 255)),
                
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}