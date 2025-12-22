import 'package:catering_app/models/cart_item.dart';
import 'package:equatable/equatable.dart';


class CartState extends Equatable {
  final Map<String, CartItem> items; // key = mealId

  const CartState({required this.items});

  factory CartState.initial() => const CartState(items: {});

  double get totalAmount =>
      items.values.fold(0, (sum, item) => sum + item.total);

  int get itemCount => items.length;

  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [items];
}
