import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_screen.dart';
import '../services/auth_service.dart';
import '../widgets/app_background.dart';
import 'menu_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    void startOrder() {
      final target = auth.isAuthenticated
          ? const MenuScreen()
          : const AuthScreen();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => target),
      );
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_cafe,
                          color: Color(0xFF8B5E3C),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UPM Cafe',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D2B1F),
                                  ),
                            ),
                            Text(
                              'Burgers & Pizzas',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF7A5A45),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 350,maxWidth: 200),
                              child: Image.asset(
                                'assets/welcome_screen.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Welcome to UPM Cafe',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D2B1F),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pick your favorites and we will call your number when it is ready.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: const Color(0xFF7A5A45)),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: startOrder,
                              child: const Text('Order Now'),
                            ),
                            TextButton(
                              onPressed: startOrder,
                              child: const Text('Sign in / Sign up'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
