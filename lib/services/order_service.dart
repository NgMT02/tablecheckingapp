import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/cart_item.dart';
import '../models/order_receipt.dart';
import 'auth_service.dart';

class OrderException implements Exception {
  OrderException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderService {
  OrderService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? authService.client;

  final AuthService _authService;
  final http.Client _client;

  Uri get _base => Uri.parse(cloudRunBaseUrl);

  Future<OrderReceipt> placeOrder({
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double total,
    String? note,
  }) async {
    if (items.isEmpty) {
      throw OrderException('Your cart is empty.');
    }

    if (!_authService.isAuthenticated) {
      throw OrderException('Please sign in before placing an order.');
    }

    if (_base.host.isEmpty || _base.scheme.isEmpty) {
      return _offlineReceipt(subtotal: subtotal, tax: tax, total: total);
    }

    final uri = _base.replace(path: '/orders');
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (!_authService.usesBrowserCookies) {
        headers.addAll(_authService.authHeaders());
      }

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'items': items
                  .map(
                    (entry) => {
                      'id': entry.item.id,
                      'name': entry.item.name,
                      'price': entry.item.price,
                      'quantity': entry.quantity,
                      'category': entry.item.category,
                    },
                  )
                  .toList(),
              'subtotal': subtotal,
              'tax': tax,
              'total': total,
              'note': note ?? '',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = _asMap(decoded);
        if (data != null) {
          final receipt = OrderReceipt.fromJson(data);
          if (receipt.ticketNumber.isNotEmpty) {
            return receipt;
          }
        }
      }

      debugPrint('Order failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Order request failed: $e');
    }

    return _offlineReceipt(subtotal: subtotal, tax: tax, total: total);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  OrderReceipt _offlineReceipt({
    required double subtotal,
    required double tax,
    required double total,
  }) {
    final now = DateTime.now();
    final ticket = 1 + Random().nextInt(999);
    return OrderReceipt(
      orderId: 'local-${now.millisecondsSinceEpoch}',
      ticketNumber: ticket.toString(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      createdAt: now,
      isOffline: true,
    );
  }
}
