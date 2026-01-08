import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'auth_service.dart';

class NowServingException implements Exception {
  NowServingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NowServingService {
  NowServingService({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? authService.client;

  final AuthService _authService;
  final http.Client _client;

  Uri get _base => Uri.parse(cloudRunBaseUrl);

  Future<int?> fetchNowServing() async {
    if (_base.host.isEmpty || _base.scheme.isEmpty) return null;

    final uri = _base.replace(path: '/now-serving');
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return _readNumber(decoded);
      }
      debugPrint('Now serving fetch failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Now serving fetch failed: $e');
    }
    return null;
  }

  Future<int?> advanceQueue() async {
    if (_base.host.isEmpty || _base.scheme.isEmpty) return null;

    final uri = _base.replace(path: '/now-serving/next');
    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (!_authService.usesBrowserCookies) {
        headers.addAll(_authService.authHeaders());
      }

      final response = await _client
          .post(uri, headers: headers, body: jsonEncode({}))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return _readNumber(decoded);
      }
      debugPrint('Advance queue failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('Advance queue failed: $e');
    }
    return null;
  }

  int? _readNumber(dynamic decoded) {
    if (decoded is Map) {
      final value = decoded['value'] ?? decoded['nowServing'];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
    }
    return null;
  }
}
