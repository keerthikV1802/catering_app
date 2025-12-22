import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:catering_app/models/order.dart';
import 'package:catering_app/data/orders_repository.dart';

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

  void _refreshOrder() async {
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
          newStatus == OrderStatus.accepted ? 'Accept Order?' : 'Reject Order?',
        ),
        content: Text(
          newStatus == OrderStatus.accepted
              ? 'This order will be sent to the chef for preparation.'
              : 'This order will be rejected. This action cannot be undone.',
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
                // Order Status Badge
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

                // Menu Items with Status
                const Text(
                  'Menu Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    fontSize: 18,
                  ),
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
                      trailing: Container(
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

                // Pricing Summary
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

          // Action Buttons at Bottom
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
                      label: const Text('Reject'),
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