import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../services/menu_service.dart';

class MenuViewModel extends ChangeNotifier {
  MenuViewModel({required MenuService service}) : _service = service;

  final MenuService _service;

  List<MenuItem> items = [];
  bool isLoading = false;
  String? error;
  bool _hasLoaded = false;

  Future<void> loadMenu({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      items = await _service.fetchMenu();
      _hasLoaded = true;
      if (items.isEmpty) {
        error = 'Menu is unavailable right now.';
      }
    } catch (e) {
      error = 'Unable to load menu: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Map<String, List<MenuItem>> get groupedByCategory {
    final Map<String, List<MenuItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }
}
