import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;
  bool isSignUp = false;
  bool isSubmitting = false;
  String? error;

  void toggleMode() {
    isSignUp = !isSignUp;
    error = null;
    notifyListeners();
  }

  Future<void> submit({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      error = 'Email and password are required.';
      notifyListeners();
      return;
    }

    if (isSignUp && password != confirmPassword) {
      error = 'Passwords do not match.';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      if (isSignUp) {
        await _authService.signUp(email: email, password: password);
      } else {
        await _authService.signIn(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      error = e.message ?? 'Authentication failed.';
    } catch (e) {
      error = 'Something went wrong: $e';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
