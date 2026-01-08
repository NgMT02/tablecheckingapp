import 'menu_item.dart';

class CartItem {
  const CartItem({
    required this.item,
    required this.quantity,
  });

  final MenuItem item;
  final int quantity;

  double get total => item.price * quantity;

  CartItem copyWith({
    MenuItem? item,
    int? quantity,
  }) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}
