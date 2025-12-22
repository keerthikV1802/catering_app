import 'package:catering_app/data/orders_repository.dart';
import 'package:catering_app/models/order.dart';
import 'package:catering_app/screens/chef_order_details.screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChefScreen extends StatefulWidget {
  static const routeName = '/chef';

  const ChefScreen({super.key});

  @override
  State<ChefScreen> createState() => _ChefScreenState();
}

class _ChefScreenState extends State<ChefScreen> {
  List<Order> _acceptedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final allOrders = await OrdersRepository.instance.getAllOrders();
    setState(() {
      _acceptedOrders = allOrders
          .where((o) =>
              o.status == OrderStatus.accepted ||
              o.status == OrderStatus.inProgress)
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _acceptedOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No orders to prepare',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _acceptedOrders.length,
                    itemBuilder: (ctx, idx) {
                      final order = _acceptedOrders[idx];
                      final completedMeals = order.mealProgress
                          .where((mp) => mp.status == MealStatus.prepared)
                          .length;
                      final totalMeals = order.meals.length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) =>
                                    ChefOrderDetailScreen(order: order),
                              ),
                            );
                            _loadOrders();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      order.categoryTitle,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: completedMeals == totalMeals
                                            ? Colors.green
                                            : Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$completedMeals/$totalMeals',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Function: ${DateFormat('dd MMM, hh:mm a').format(order.functionDate)}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  'Guests: ${order.guestCount} | Venue: ${order.venue}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: totalMeals > 0
                                      ? completedMeals / totalMeals
                                      : 0,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    completedMeals == totalMeals
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}