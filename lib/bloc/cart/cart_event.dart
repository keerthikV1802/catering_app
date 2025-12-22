import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

// Add item (from meal card)
class AddMealToCart extends CartEvent {
  final String mealId;
  final String title;
  final double pricePerPlate;

  const AddMealToCart({
    required this.mealId,
    required this.title,
    required this.pricePerPlate,
  });

  @override
  List<Object?> get props => [mealId, title, pricePerPlate];
}

// Remove completely
class RemoveMealFromCart extends CartEvent {
  final String mealId;

  const RemoveMealFromCart(this.mealId);

  @override
  List<Object?> get props => [mealId];
}

// Change quantity (increase / decrease)
class ChangeCartQuantity extends CartEvent {
  final String mealId;
  final int quantity;

  const ChangeCartQuantity({
    required this.mealId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [mealId, quantity];
}

// Clear whole cart (after order success)
class ClearCart extends CartEvent {
  const ClearCart();
}
