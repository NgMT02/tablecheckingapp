import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartViewModel extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList()
    ..sort((a, b) => a.item.name.compareTo(b.item.name));

  bool get isEmpty => _items.isEmpty;

  int get totalItems =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0, (sum, item) => sum + item.total);

  double get tax => subtotal * defaultTaxRate;

  double get total => subtotal + tax;

  void addItem(MenuItem item) {
    final existing = _items[item.id];
    if (existing == null) {
      _items[item.id] = CartItem(item: item, quantity: 1);
    } else {
      _items[item.id] = existing.copyWith(quantity: existing.quantity + 1);
    }
    notifyListeners();
  }

  void updateQuantity(MenuItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item.id);
    } else {
      _items[item.id] = CartItem(item: item, quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(MenuItem item) {
    _items.remove(item.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
