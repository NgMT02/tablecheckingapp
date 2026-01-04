import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'http_client_factory_stub.dart'
    if (dart.library.html) 'http_client_factory_web.dart'
    if (dart.library.io) 'http_client_factory_io.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  AuthService({http.Client? client})
      : _client = client ?? createHttpClient();

  final http.Client _client;

  bool _isAuthenticated = false;
  bool _hasLoadedInitialState = true; // no async init needed
  String? _email;
  String? _sessionCookie; // only used for non-web clients

  bool get isAuthenticated => _isAuthenticated;
  bool get hasLoadedInitialState => _hasLoadedInitialState;
  String? get currentEmail => _email;
  http.Client get client => _client;
  bool get usesBrowserCookies => kIsWeb;

  Uri get _base => Uri.parse(cloudRunBaseUrl);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authRequest(
      path: '/auth/signin',
      email: email,
      password: password,
      onSuccess: () {
        _email = email.trim();
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _authRequest(
      path: '/auth/signup',
      email: email,
      password: password,
      onSuccess: () {
        _email = email.trim();
      },
    );
  }

  Future<void> _authRequest({
    required String path,
    required String email,
    required String password,
    required VoidCallback onSuccess,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      throw AuthException('Email and password are required.');
    }

    final uri = _base.replace(path: path);
    final response = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': trimmedEmail,
        'password': trimmedPassword,
      }),
    );

    _storeSessionCookie(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _isAuthenticated = true;
      onSuccess();
      notifyListeners();
      return;
    }

    final raw = _extractError(response.body);
    final message = _friendlyAuthError(response.statusCode, raw);
    throw AuthException(message);
  }

  Future<void> signOut() async {
    final uri = _base.replace(path: '/auth/signout');
    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ..._cookieHeaderIfNeeded(),
      };
      await _client.post(uri, headers: headers);
    } catch (_) {
      // ignore network errors on sign-out
    } finally {
      _isAuthenticated = false;
      _email = null;
      _sessionCookie = null;
      notifyListeners();
    }
  }

  Map<String, String> authHeaders() {
    if (kIsWeb) {
      // Browser will include cookies when withCredentials is true.
      return {};
    }
    final cookies = _cookieHeaderIfNeeded();
    if (!_isAuthenticated || cookies.isEmpty) {
      throw AuthException('You are not signed in.');
    }
    return cookies;
  }

  Map<String, String> _cookieHeaderIfNeeded() {
    if (_sessionCookie == null) return {};
    return {'cookie': _sessionCookie!};
  }

  void _storeSessionCookie(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;

    // Expecting "session=<value>; Path=/; HttpOnly; ..."
    final sessionPart = setCookie.split(';').firstWhere(
      (part) => part.trim().startsWith('session='),
      orElse: () => '',
    );
    if (sessionPart.isNotEmpty) {
      _sessionCookie = sessionPart.trim();
    }
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return null;
  }

  String _friendlyAuthError(int statusCode, String? raw) {
    if (statusCode == 400 || statusCode == 401) {
      return 'Email or password is incorrect.';
    }
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
