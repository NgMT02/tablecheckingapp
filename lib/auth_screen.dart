import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'viewmodels/auth_view_model.dart';
import 'widgets/app_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _didNavigate = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        authService: context.read<AuthService>(),
      ),
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<AuthViewModel>();
          final auth = context.watch<AuthService>();

          if (auth.isAuthenticated && !_didNavigate) {
            _didNavigate = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          }

          final title =
              viewModel.isSignUp ? 'Create an account' : 'Welcome back';
          final actionLabel = viewModel.isSignUp ? 'Sign up' : 'Sign in';
          final toggleLabel = viewModel.isSignUp
              ? 'Already have an account? Sign in'
              : 'Need an account? Sign up';

          return Scaffold(
            body: AppBackground(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: const Color(0xFFFFF3E8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF8F2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_cafe,
                                    color: Color(0xFF8B5E3C),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'UPM Cafe',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: const Color(0xFF3D2B1F),
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sign in to start ordering',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF7A5A45),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 26,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF3D2B1F),
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Use your email to continue.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF7A5A45),
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'you@example.com',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                    ),
                                    obscureText: true,
                                  ),
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: viewModel.isSignUp
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(top: 12.0),
                                            child: TextField(
                                              controller: _confirmController,
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Confirm password',
                                              ),
                                              obscureText: true,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  const SizedBox(height: 22),
                                  ElevatedButton(
                                    onPressed: viewModel.isSubmitting
                                        ? null
                                        : () => viewModel.submit(
                                              email: _emailController.text,
                                              password:
                                                  _passwordController.text,
                                              confirmPassword:
                                                  _confirmController.text,
                                            ),
                                    child: viewModel.isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(actionLabel),
                                  ),
                                  TextButton(
                                    onPressed: viewModel.isSubmitting
                                        ? null
                                        : viewModel.toggleMode,
                                    child: Text(toggleLabel),
                                  ),
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: viewModel.error != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12.0,
                                            ),
                                            child: Text(
                                              viewModel.error!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .error,
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
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
        },
      ),
    );
  }
}
