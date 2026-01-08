import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../viewmodels/cart_view_model.dart';
import '../widgets/app_background.dart';
import 'confirm_order_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

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
          width: 56,
          height: 56,
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
          width: 56,
          height: 56,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: cart.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Your cart is empty.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3D2B1F),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a few items from the menu to get started.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: const Color(0xFF7A5A45)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Browse menu'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final entry = cart.items[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7E6D7),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildItemImage(entry.item),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.item.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    const Color(0xFF3D2B1F),
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'RM ${entry.item.price.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color:
                                                    const Color(0xFF7A5A45),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => cart.updateQuantity(
                                          entry.item,
                                          entry.quantity - 1,
                                        ),
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Color(0xFF8B5E3C),
                                        ),
                                      ),
                                      Text(
                                        entry.quantity.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF3D2B1F),
                                            ),
                                      ),
                                      IconButton(
                                        onPressed: () => cart.updateQuantity(
                                          entry.item,
                                          entry.quantity + 1,
                                        ),
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Color(0xFF8B5E3C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
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
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ConfirmOrderScreen(),
                                  ),
                                );
                              },
                              child: const Text('Confirm Order'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
