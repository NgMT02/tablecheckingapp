import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_screen.dart';
import 'enterphone.dart';
import 'services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.hasLoadedInitialState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      return const AuthScreen();
    }

    return const EnterPhoneScreen();
  }
}
