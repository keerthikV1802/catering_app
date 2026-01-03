import 'package:catering_app/data/orders_repository.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  static const routeName = '/orders';
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Orders')),
      body: StreamBuilder(
        stream: OrdersRepository.instance.watchOrders(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final o = orders[i];
              return ListTile(
                title: Text(o.categoryTitle),
                subtitle: Text(
                    '${o.guestCount} guests Rs. ${o.finalAmount.toStringAsFixed(0)}'),
              );
            },
          );
        },
      ),
    );
  }
}
