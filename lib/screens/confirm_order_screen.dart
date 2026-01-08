import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../viewmodels/cart_view_model.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets/app_background.dart';
import 'now_serving_screen.dart';

class ConfirmOrderScreen extends StatefulWidget {
  const ConfirmOrderScreen({super.key});

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  final _noteController = TextEditingController();
  static const Map<String, String> _assetOverrides = {
    'burger-1': 'assets/menu/cheese burger.jpg',
    'burger-2': 'assets/menu/chicken burger.jpg',
    'pizza-1': 'assets/menu/pepperoni pizza.jpg',
    'drink-1': 'assets/menu/latte.jpg',
  };

  Widget _buildItemImage(MenuItem item) {
    final assetPath = item.assetPath ?? _assetOverrides[item.id];
    if (assetPath != null && assetPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackIcon();
          },
        ),
      );
    }

    final url = item.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackIcon();
          },
        ),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return const Icon(
      Icons.local_cafe,
      color: Color(0xFFD39A76),
      size: 22,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartViewModel>();
    final viewModel = context.read<OrderViewModel>();

    final receipt = await viewModel.placeOrder(
      items: cart.items,
      subtotal: cart.subtotal,
      tax: cart.tax,
      total: cart.total,
      note: _noteController.text,
    );

    if (!mounted) return;

    if (receipt != null) {
      cart.clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NowServingScreen(receipt: receipt),
        ),
      );
    } else if (viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    final order = context.watch<OrderViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Order'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review your items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2B1F),
                      ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final entry = cart.items[index];
                      return Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7E6D7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildItemImage(entry.item),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${entry.quantity}x ${entry.item.name}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF7A5A45),
                                  ),
                            ),
                          ),
                          Text(
                            'RM ${entry.total.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D2B1F),
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryRow(label: 'Subtotal', value: cart.subtotal),
                        const SizedBox(height: 6),
                        _SummaryRow(label: 'Tax', value: cart.tax),
                        const Divider(height: 20),
                        _SummaryRow(
                          label: 'Total',
                          value: cart.total,
                          isEmphasis: true,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Less ice, no onions, etc.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              order.isSubmitting ? null : () => _placeOrder(context),
                          child: order.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Place Order'),
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final double value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final style = isEmphasis
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D2B1F),
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7A5A45),
            );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('RM ${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
