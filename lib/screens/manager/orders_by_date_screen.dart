import 'package:catering_app/screens/manager/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/models/order.dart';
import 'package:catering_app/data/orders_repository.dart';

class OrdersByDateScreen extends StatefulWidget {
  final DateTime date;
  final List<Order> orders;

  const OrdersByDateScreen({
    super.key,
    required this.date,
    required this.orders,
  });

  @override
  State<OrdersByDateScreen> createState() => _OrdersByDateScreenState();
}

class _OrdersByDateScreenState extends State<OrdersByDateScreen> {
  late List<Order> _currentOrders;

  @override
  void initState() {
    super.initState();
    _currentOrders = widget.orders;
  }

  Future<void> _refreshOrders() async {
    final updatedOrders = await OrdersRepository.instance.getOrdersForDate(widget.date);
    setState(() {
      _currentOrders = updatedOrders;
    });
  }

  Future<void> _navigateToOrderDetails(Order order) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: order),
      ),
    );

    // If result is true, it means order was deleted
    if (result == true) {
      await _refreshOrders();
      
      // If no orders left for this date, go back to calendar
      if (_currentOrders.isEmpty && mounted) {
        Navigator.of(context).pop(true); // Tell calendar to refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders - ${widget.date.day}/${widget.date.month}/${widget.date.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _currentOrders.isEmpty
          ? const Center(
              child: Text(
                'No orders for this date',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _currentOrders.length,
              itemBuilder: (ctx, i) {
                final o = _currentOrders[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      o.categoryTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${o.guestCount} guests Rs. €¢ Rs. ${o.totalAmount.toStringAsFixed(0)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _navigateToOrderDetails(o),
                  ),
                );
              },
            ),
    );
  }
}