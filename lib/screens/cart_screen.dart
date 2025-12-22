import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:catering_app/bloc/cart/cart_bloc.dart';
import 'package:catering_app/bloc/cart/cart_state.dart';
import 'package:catering_app/bloc/cart/cart_event.dart';

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';

  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _functionDateTime;
  final _venueController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _venueController.dispose();
    _guestCountController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      _functionDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  // ➕ add custom item dialog
  void _showAddCustomItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add custom item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price per plate (₹)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0;
              final qty = int.tryParse(qtyController.text) ?? 1;

              if (name.isEmpty || price <= 0 || qty <= 0) {
                return;
              }

              final cartBloc = context.read<CartBloc>();
              final id = 'custom-${DateTime.now().millisecondsSinceEpoch}';

              cartBloc.add(AddMealToCart(
                mealId: id,
                title: name,
                pricePerPlate: price,
              ));

              cartBloc.add(ChangeCartQuantity(
                mealId: id,
                quantity: qty,
              ));

              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _placeOrder(CartState state) {
    if (!_formKey.currentState!.validate() || _functionDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required details')),
      );
      return;
    }

    final guestCount = int.tryParse(_guestCountController.text) ?? 0;
    final perPlateTotal = state.totalAmount;
    final totalForEvent = guestCount > 0 ? perPlateTotal * guestCount : 0;

    // 👉 here you would normally create Order model and save to backend
    // for now we just clear cart and show summary

    context.read<CartBloc>().add(const ClearCart());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order placed!',style: TextStyle(color: Colors.white),),
        content: Text(
          'Function on: ${_functionDateTime!}\n'
          'Guests: $guestCount\n'
          'Estimated total: ₹${totalForEvent.toStringAsFixed(0)}\n\n'
          'Note: Please pay token advance to confirm your event booking.',style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();      // close dialog
              Navigator.of(context).pop();  // go back from cart screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Text(
                " cart is empty!",
                style: TextStyle(fontSize: 28,color: Colors.white),
              ),
            );
          }

          final cartItems = state.items.values.toList();
          final guestCount = int.tryParse(_guestCountController.text) ?? 0;
          final eventTotal = guestCount > 0
              ? state.totalAmount * guestCount
              : state.totalAmount;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🧾 cart list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    itemBuilder: (ctx, index) {
                      final item = cartItems[index];

                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          "₹${item.pricePerPlate.toStringAsFixed(0)} x ${item.quantity} = ₹${item.total.toStringAsFixed(0)}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            context
                                .read<CartBloc>()
                                .add(RemoveMealFromCart(item.mealId));
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Per-plate Total:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,color: Colors.amber),
                      ),
                      Text(
                        "₹${state.totalAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,color: Colors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Event Total (× guests):",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,color: Colors.amber),
                      ),
                      Text(
                        "₹${eventTotal.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ➕ custom item button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showAddCustomItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add item (not in list)'),
                    ),
                  ),

                  const Divider(height: 32),

                  // 📝 checkout form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // function date & time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _functionDateTime == null
                                    ? 'Select function date & time *'
                                    : 'Function: ${_functionDateTime.toString()}',style: TextStyle(color: Colors.amber,fontSize: 15),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _pickDateTime,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _venueController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Venue / address *',
                            border: OutlineInputBorder(),
                            hintStyle:  TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter venue/address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _guestCountController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Expected guest count *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final n = int.tryParse(value ?? '');
                            if (n == null || n <= 0) {
                              return 'Enter valid guest count';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contactNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Contact name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter contact name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contactPhoneController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Contact phone *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().length < 10) {
                              return 'Enter valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _budgetController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText:
                                'Your budget (negotiable amount) – optional',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes / special instructions *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please add any notes or write "None"';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Note: To confirm your event, please pay a token advance after order discussion with catering owner.',
                          style: TextStyle(fontSize: 12,color: Color.fromARGB(255, 231, 3, 3)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _placeOrder(state),
                            child: const Text('Place Order'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
