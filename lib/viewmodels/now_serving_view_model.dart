import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/now_serving_service.dart';

class NowServingViewModel extends ChangeNotifier {
  NowServingViewModel({required NowServingService service}) : _service = service;

  final NowServingService _service;

  int? currentNumber;
  String? error;
  bool isLoading = false;

  Timer? _timer;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final value = await _service.fetchNowServing();
      if (value != null) {
        currentNumber = value;
      }
    } catch (e) {
      error = 'Unable to fetch now serving: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    if (_timer != null) return;
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> advanceQueue() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final value = await _service.advanceQueue();
      if (value != null) {
        currentNumber = value;
      }
    } catch (e) {
      error = 'Unable to advance queue: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
