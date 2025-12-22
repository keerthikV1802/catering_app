import 'package:catering_app/data/orders_repository.dart';
import 'package:catering_app/models/order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChefOrderDetailScreen extends StatefulWidget {
  final Order order;

  const ChefOrderDetailScreen({super.key, required this.order});

  @override
  State<ChefOrderDetailScreen> createState() => _ChefOrderDetailScreenState();
}

class _ChefOrderDetailScreenState extends State<ChefOrderDetailScreen> {
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateMealStatus(MealProgress mealProgress, MealStatus newStatus) async {
    await OrdersRepository.instance.updateMealStatus(
      _order.id,
      mealProgress.mealId,
      newStatus,
    );

    final updated = await OrdersRepository.instance.getOrderById(_order.id);
    if (updated != null && mounted) {
      setState(() {
        _order = updated;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Meals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _order.categoryTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Function: ${DateFormat('dd MMM yyyy, hh:mm a').format(_order.functionDate)}'),
                  Text('Guests: ${_order.guestCount}'),
                  Text('Venue: ${_order.venue}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Meals to Prepare',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._order.meals.map((meal) {
            final progress = _order.mealProgress.firstWhere(
              (mp) => mp.mealTitle == meal.title,
              orElse: () => MealProgress(
                mealId: meal.id,
                mealTitle: meal.title,
              ),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            meal.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                            progress.status.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: progress.status == MealStatus.notStarted
                                ? () => _updateMealStatus(
                                    progress, MealStatus.preparing)
                                : null,
                            child: const Text('Start'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: progress.status == MealStatus.preparing
                                ? () => _updateMealStatus(
                                    progress, MealStatus.prepared)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Complete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}