import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/table_entry.dart';
import 'auth_service.dart';

class LookupException implements Exception {
  LookupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TableNotFoundException extends LookupException {
  TableNotFoundException(String message) : super(message);
}

class TableLookupService {
  TableLookupService({
    http.Client? client,
    required AuthService authService,
  })  : _client = client ?? authService.client,
        _authService = authService;

  final http.Client _client;
  final AuthService _authService;

  Uri get _serviceBase => Uri.parse(cloudRunBaseUrl);

  Future<TableEntry> lookupTableByPhone(String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Please enter a phone number.');
    }

    if (_serviceBase.host.isEmpty || _serviceBase.scheme.isEmpty) {
      throw LookupException('Cloud Run base URL is not configured.');
    }

    if (!_authService.isAuthenticated) {
      throw LookupException('Please sign in before requesting a table.');
    }

    final payload = {'phoneNumber': trimmed, 'phone': trimmed};

    final primaryUri = _serviceBase.replace(path: '/table');
    final fallbackUri = _serviceBase;

    Uri attemptedUri = primaryUri;
    try {
      var response = await _post(
        primaryUri,
        body: payload,
        label: 'primary /table endpoint',
      );

      if (response == null ||
          response.statusCode == 404 ||
          response.statusCode == 405) {
        attemptedUri = fallbackUri;
        response = await _post(
          fallbackUri,
          body: payload,
          label: 'fallback root endpoint',
        );
      }

      if (response == null) {
        throw LookupException(
          'Unable to reach the server. Check your connection or CORS.',
        );
      }

      final requestUrl = response.request?.url ?? attemptedUri;
      debugPrint(
        'POST $requestUrl => ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data =
            _asMap(decoded) ??
            (decoded is Map ? _asMap(decoded['data']) : null);

        if (data != null) {
          var entry = TableEntry.fromJson(data);
          if (entry.phoneNumber.isEmpty) {
            entry = TableEntry(
              phoneNumber: trimmed,
              tableNumber: entry.tableNumber,
            );
          }
          if (entry.tableNumber.isNotEmpty) {
            return entry;
          }
        }

        throw TableNotFoundException('No table found for that phone number.');
      } else if (response.statusCode == 404) {
        throw TableNotFoundException('No table found for that phone number.');
      } else {
        throw LookupException(
          'Server error (${response.statusCode}). Try again.',
        );
      }
    } on FormatException catch (_) {
      rethrow;
    } catch (e) {
      if (e is LookupException) rethrow;
      debugPrint('Lookup error: $e');
      throw LookupException(
        'Unable to reach the server. Check your connection or CORS.',
      );
    }
  }

  Future<http.Response?> _post(
    Uri uri, {
    required Map<String, String> body,
    required String label,
  }) async {
    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      headers.addAll(_authService.authHeaders());

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      debugPrint('POST ($label) $uri => ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('POST ($label) $uri failed: $e');
      return null;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
