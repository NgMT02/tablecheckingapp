import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order_receipt.dart';
import '../services/order_service.dart';

enum OrderStatus { idle, submitting, success, failure }

class OrderViewModel extends ChangeNotifier {
  OrderViewModel({required OrderService service}) : _service = service;

  final OrderService _service;

  OrderStatus status = OrderStatus.idle;
  OrderReceipt? receipt;
  String? error;

  bool get isSubmitting => status == OrderStatus.submitting;

  Future<OrderReceipt?> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double total,
    String? note,
  }) async {
    status = OrderStatus.submitting;
    error = null;
    notifyListeners();

    try {
      receipt = await _service.placeOrder(
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        note: note,
      );
      status = OrderStatus.success;
      return receipt;
    } on OrderException catch (e) {
      status = OrderStatus.failure;
      error = e.message;
    } catch (e) {
      status = OrderStatus.failure;
      error = 'Something went wrong: $e';
    } finally {
      notifyListeners();
    }

    return null;
  }

  void reset() {
    status = OrderStatus.idle;
    error = null;
    receipt = null;
    notifyListeners();
  }
}
