class CartItem {
  final String mealId;
  final String title;
  final int quantity;
  final double pricePerPlate;

  double get total => quantity * pricePerPlate;

  CartItem({
    required this.mealId,
    required this.title,
    required this.quantity,
    required this.pricePerPlate,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      mealId: mealId,
      title: title,
      quantity: quantity ?? this.quantity,
      pricePerPlate: pricePerPlate,
    );
  }
}
