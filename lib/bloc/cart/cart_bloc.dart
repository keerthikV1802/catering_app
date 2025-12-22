import 'package:catering_app/models/cart_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState.initial()) {
    on<AddMealToCart>(_onAddMeal);
    on<RemoveMealFromCart>(_onRemoveMeal);
    on<ChangeCartQuantity>(_onChangeQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddMeal(AddMealToCart event, Emitter<CartState> emit) {
    final current = Map<String, CartItem>.from(state.items);

    if (current.containsKey(event.mealId)) {
      final existing = current[event.mealId]!;
      current[event.mealId] =
          existing.copyWith(quantity: existing.quantity + 1);
    } else {
      current[event.mealId] = CartItem(
        mealId: event.mealId,
        title: event.title,
        quantity: 1,
        pricePerPlate: event.pricePerPlate,
      );
    }

    emit(state.copyWith(items: current));
  }

  void _onRemoveMeal(RemoveMealFromCart event, Emitter<CartState> emit) {
    final current = Map<String, CartItem>.from(state.items);
    current.remove(event.mealId);
    emit(state.copyWith(items: current));
  }

  void _onChangeQuantity(ChangeCartQuantity event, Emitter<CartState> emit) {
    final current = Map<String, CartItem>.from(state.items);
    final existing = current[event.mealId];
    if (existing == null) return;

    if (event.quantity <= 0) {
      current.remove(event.mealId);
    } else {
      current[event.mealId] = existing.copyWith(quantity: event.quantity);
    }

    emit(state.copyWith(items: current));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartState.initial());
  }
}
