import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/orders/presentation/pages/order_summary_page.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/domain/entities/product_pricing.dart';
import 'package:staff_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:staff_app/features/products/presentation/widgets/product_image_carousel.dart';

class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key, this.category});

  /// When set, only products of this category are shown (pushed from the
  /// categories screen). Null means all products.
  final String? category;

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(widget.category ?? 'All Products'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CartButton(
              count: cart.length,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderSummaryPage()),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search products by name or code',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Message(
                icon: Icons.error_outline,
                text: 'Failed to load products.\n$error',
                onRetry: () => ref.invalidate(productsProvider),
              ),
              data: (products) {
                final filtered = _filter(products);
                if (filtered.isEmpty) {
                  return const _Message(
                    icon: Icons.inventory_2_outlined,
                    text: 'No products found.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(productsProvider);
                    await ref.read(productsProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        ProductCard(product: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _filter(List<Product> products) {
    var scoped = products;
    final category = widget.category?.trim().toLowerCase();
    if (category != null && category.isNotEmpty) {
      scoped = scoped
          .where((product) => product.category.trim().toLowerCase() == category)
          .toList();
    }
    if (_query.isEmpty) return scoped;
    final query = _query.toLowerCase();
    return scoped.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  }
}

class CartButton extends StatelessWidget {
  const CartButton({super.key, required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact product card: auto-scrolling images, name, stock and price range.
/// Tapping opens the full detail page with all price combinations.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(salesmanMarketTypeProvider);
    final outOfStock = product.availableStock <= 0;
    final prices = product.units
        .map(
          (unit) =>
              resolveUnitOfferPrice(product, market, unit) ??
              resolveUnitPrice(product, market, unit),
        )
        .where((price) => price > 0)
        .toList()
      ..sort();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductImageCarousel(
                  imageUrls: productImages(product),
                  height: 190,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Badge(
                    text: outOfStock
                        ? 'Out of stock'
                        : 'Stock ${_trim(product.availableStock)} ${product.baseUnit}',
                    color: outOfStock
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF047857),
                  ),
                ),
                if (product.category.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _Badge(
                      text: product.category,
                      color: const Color(0xFF374151),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Code: ${product.code}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prices.isEmpty
                                  ? 'Price not set'
                                  : prices.length == 1
                                  ? 'QAR ${prices.first.toStringAsFixed(2)}'
                                  : 'From QAR ${prices.first.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF047857),
                              ),
                            ),
                            Text(
                              '${product.units.length} unit type'
                              '${product.units.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailPage(product: product),
                          ),
                        ),
                        icon: const Icon(Icons.tune, size: 17),
                        label: const Text('View & Order'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF9CA3AF)),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

String _trim(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
