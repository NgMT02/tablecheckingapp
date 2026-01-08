import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_receipt.dart';
import '../viewmodels/now_serving_view_model.dart';
import '../widgets/app_background.dart';

class NowServingScreen extends StatefulWidget {
  const NowServingScreen({super.key, required this.receipt});

  final OrderReceipt receipt;

  @override
  State<NowServingScreen> createState() => _NowServingScreenState();
}

class _NowServingScreenState extends State<NowServingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NowServingViewModel>().startPolling();
    });
  }

  @override
  void dispose() {
    context.read<NowServingViewModel>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NowServingViewModel>();
    final nowServing = viewModel.currentNumber;
    final ticket = int.tryParse(widget.receipt.ticketNumber);
    final isCalled =
        nowServing != null && ticket != null && nowServing >= ticket;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.local_cafe,
                              size: 48,
                              color: Color(0xFFD39A76),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Now Serving',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D2B1F),
                                  ),
                            ),
                            const SizedBox(height: 14),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.85, end: 1),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Text(
                                nowServing?.toString() ?? '--',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF3D2B1F),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your number: ${widget.receipt.ticketNumber}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D2B1F),
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isCalled
                                  ? 'Your food is ready to be served.'
                                  : 'Please wait for your number to be called.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: const Color(0xFF7A5A45)),
                              textAlign: TextAlign.center,
                            ),
                            if (viewModel.error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                viewModel.error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: const Color(0xFF7A5A45)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if (widget.receipt.isOffline) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Saved locally. Sync with staff when online.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: const Color(0xFF7A5A45)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: const Text('Back to menu'),
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
