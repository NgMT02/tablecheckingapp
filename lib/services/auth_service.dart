import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _subscription = _auth.authStateChanges().listen((user) {
      _user = user;
      _hasLoadedInitialState = true;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  StreamSubscription<User?>? _subscription;
  User? _user;
  bool _hasLoadedInitialState = false;

  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;
  bool get hasLoadedInitialState => _hasLoadedInitialState;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    _user = credential.user;
    notifyListeners();
    return credential;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    _user = credential.user;
    notifyListeners();
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<String?> getIdToken() async {
    return _user?.getIdToken();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
