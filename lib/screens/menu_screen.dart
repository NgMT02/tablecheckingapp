import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../services/auth_service.dart';
import '../viewmodels/cart_view_model.dart';
import '../viewmodels/menu_view_model.dart';
import '../viewmodels/now_serving_view_model.dart';
import '../viewmodels/order_view_model.dart';
import '../widgets/app_background.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const Map<String, String> _assetOverrides = {
    'burger-1': 'assets/menu/cheese burger.jpg',
    'burger-2': 'assets/menu/chicken burger.jpg',
    'pizza-1': 'assets/menu/pepperoni pizza.jpg',
    'drink-1': 'assets/menu/latte.jpg',
  };

  String? _resolveAssetPath(MenuItem item) {
    final direct = item.assetPath;
    if (direct != null && direct.isNotEmpty) return direct;
    return _assetOverrides[item.id];
  }

  Widget _buildItemImage(MenuItem item, {double size = 52}) {
    final bytes = item.imageBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      );
    }

    final assetPath = _resolveAssetPath(item);
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(item, size: size);
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
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(item, size: size);
          },
        ),
      );
    }

    return _buildFallbackIcon(item, size: size);
  }

  Widget _buildFallbackIcon(MenuItem item, {double size = 52}) {
    return Icon(
      item.isPopular ? Icons.local_fire_department : Icons.restaurant,
      color: const Color(0xFFF59E0B),
      size: size * 0.45,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MenuViewModel>().loadMenu();
      context.read<NowServingViewModel>().startPolling();
    });
  }

  Widget _buildQueueBanner(
    BuildContext context,
    NowServingViewModel nowServing,
    OrderViewModel orders,
  ) {
    final current = nowServing.currentNumber;
    final receipt = orders.receipt;
    final ticket =
        receipt != null ? int.tryParse(receipt.ticketNumber) : null;
    final isReady = current != null && ticket != null && current >= ticket;

    return Card(
      color: const Color(0xFFFFF8F2),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Now Serving',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2B1F),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              current?.toString() ?? '--',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D2B1F),
                  ),
            ),
            const SizedBox(height: 10),
            if (receipt != null) ...[
              Text(
                'Your number: ${receipt.ticketNumber}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A5A45),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                isReady
                    ? 'Your food is ready to be served.'
                    : 'We will call your number soon.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A5A45),
                    ),
              ),
            ] else ...[
              Text(
                'Place an order to get your number.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A5A45),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coffee Menu'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cart.totalItems > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        cart.totalItems.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'signout') {
                await context.read<AuthService>().signOut();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
              if (value == 'refresh') {
                context.read<MenuViewModel>().loadMenu(forceRefresh: true);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh menu')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Consumer<MenuViewModel>(
            builder: (context, viewModel, _) {
              final nowServing = context.watch<NowServingViewModel>();
              final orders = context.watch<OrderViewModel>();
              if (viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.error != null && viewModel.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          viewModel.error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              viewModel.loadMenu(forceRefresh: true),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final grouped = viewModel.groupedByCategory;
              final entries = grouped.entries.toList();

              final children = <Widget>[
                _buildQueueBanner(context, nowServing, orders),
              ];
              for (final entry in entries) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF7A5A45),
                              ),
                        ),
                        const SizedBox(height: 12),
                        ...entry.value.map(
                          (item) => Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: const Color(0xFFFFF8F2),
                            elevation: 6,
                            shadowColor: Colors.black.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7E6D7),
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: _buildItemImage(item, size: 170),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    item.name,
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
                                    item.description,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF7A5A45),
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'RM ${item.price.toStringAsFixed(2)}',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF3D2B1F),
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 160,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context
                                              .read<CartViewModel>()
                                              .addItem(item);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${item.name} added to cart',
                                              ),
                                              duration: const Duration(
                                                milliseconds: 1200,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Add to Cart'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                children: children,
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: cart.totalItems == 0
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.totalItems} items',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: const Color(0xFF7A5A45)),
                          ),
                          Text(
                            'RM ${cart.total.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3D2B1F),
                                ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 160,
                        minHeight: 44,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 44),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CartScreen(),
                            ),
                          );
                        },
                        child: const Text('View Cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
