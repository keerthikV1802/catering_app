import 'package:catering_app/models/order.dart';

class OrderDateHelper {
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Map<String, List<Order>> groupByDate(List<Order> orders) {
    final Map<String, List<Order>> map = {};
    for (final o in orders) {
      final key = dateKey(o.functionDate);
      map.putIfAbsent(key, () => []);
      map[key]!.add(o);
    }
    return map;
  }
}
