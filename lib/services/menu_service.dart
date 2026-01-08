import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/menu_item.dart';
import 'auth_service.dart';

class MenuService {
  MenuService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? authService.client;

  final AuthService _authService;
  final http.Client _client;

  Uri get _base => Uri.parse(cloudRunBaseUrl);

  Future<List<MenuItem>> fetchMenu() async {
    if (_base.host.isEmpty || _base.scheme.isEmpty) {
      return _sampleMenu();
    }

    final uri = _base.replace(path: '/menu');
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      if (_authService.isAuthenticated && !_authService.usesBrowserCookies) {
        headers.addAll(_authService.authHeaders());
      }

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final list = _extractList(decoded);
        if (list != null && list.isNotEmpty) {
          return list
              .map((item) => MenuItem.fromJson(item))
              .where((item) => item.name.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Menu fetch failed: $e');
    }

    return _sampleMenu();
  }

  List<Map<String, dynamic>>? _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded.map((item) => _asMap(item)).whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map) {
      final data = decoded['data'] ?? decoded['items'] ?? decoded['menu'];
      if (data is List) {
        return data.map((item) => _asMap(item)).whereType<Map<String, dynamic>>().toList();
      }
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<MenuItem> _sampleMenu() {
    return const [
      MenuItem(
        id: 'burger-1',
        name: 'Cheeseburger',
        description: 'Juicy beef patty with cheddar and fresh lettuce.',
        category: 'Burgers',
        price: 8.90,
        isPopular: true,
        assetPath: 'assets/menu/cheese_burger.jpg',
      ),
      MenuItem(
        id: 'burger-2',
        name: 'Chicken Burger',
        description: 'Grilled chicken, tomato, and house sauce.',
        category: 'Burgers',
        price: 8.40,
        assetPath: 'assets/menu/chicken_burger.jpg',
      ),
      MenuItem(
        id: 'pizza-1',
        name: 'Pepperoni Pizza',
        description: 'Stone-baked with mozzarella and pepperoni.',
        category: 'Pizza',
        price: 11.50,
        isPopular: true,
        assetPath: 'assets/menu/pepperoni_pizza.jpg',
      ),
      
      MenuItem(
        id: 'drink-1',
        name: 'Latte',
        description: 'Smooth espresso with chilled milk.',
        category: 'Drinks',
        price: 5.20,
        assetPath: 'assets/menu/latte.jpg',
      ),
     
    ];
  }
}
