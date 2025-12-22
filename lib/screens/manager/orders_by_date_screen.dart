import 'package:catering_app/screens/manager/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:catering_app/models/order.dart';

class OrdersByDateScreen extends StatelessWidget {
  final DateTime date;
  final List<Order> orders;

  const OrdersByDateScreen({
    super.key,
    required this.date,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Orders - ${date.day}/${date.month}/${date.year}'),
      ),
      body: ListView.builder(
  itemCount: orders.length,
  itemBuilder: (ctx, i) {
    final o = orders[i];
    return ListTile(
      title: Text(o.categoryTitle),
      subtitle: Text(
        '${o.guestCount} guests • ₹${o.totalAmount.toStringAsFixed(0)}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: o),
          ),
        );
      },
    );
  },
),

    );
  }
}
