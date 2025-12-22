import 'package:flutter/material.dart';
import 'package:catering_app/data/orders_repository.dart';
import 'package:catering_app/models/order.dart';
import 'package:catering_app/utils/order_date_helper.dart';
import 'orders_by_date_screen.dart';

class ManagerCalendarScreen extends StatefulWidget {
  const ManagerCalendarScreen({super.key});

  @override
  State<ManagerCalendarScreen> createState() => _ManagerCalendarScreenState();
}

class _ManagerCalendarScreenState extends State<ManagerCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  List<Order> _orders = [];
  Map<String, List<Order>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
  final orders = await OrdersRepository.instance.watchOrders().first;
  setState(() {
    _orders = orders;
    _grouped = OrderDateHelper.groupByDate(orders);
  });
}


  void _goToday() {
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        
      ),
      body: Column(
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left)),
                Text(
                  '${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
                IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),

          // Calendar grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: daysInMonth,
              itemBuilder: (ctx, index) {
                final day = index + 1;
                final date = DateTime(
                    _currentMonth.year, _currentMonth.month, day);
                final key = OrderDateHelper.dateKey(date);
                final count = _grouped[key]?.length ?? 0;
                final isToday = _isSameDay(date, DateTime.now());

                return InkWell(
                  onTap: count == 0
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrdersByDateScreen(
                                date: date,
                                orders: _grouped[key]!,
                              ),
                            ),
                          );
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.orange.withOpacity(0.25)
                          : const Color.fromARGB(255, 218, 211, 211),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        if (count > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 12),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int m) => const [
        'January','February','March','April','May','June',
        'July','August','September','October','November','December'
      ][m - 1];
}
