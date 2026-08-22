import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/orders/presentation/pages/order_summary_page.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/presentation/pages/products_list_page.dart';
import 'package:staff_app/features/products/presentation/providers/category_images_provider.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';

/// Landing screen of the Products tab: pick a category first, then browse
/// that category's products. Categories are derived from the live product
/// stream so they always match what is actually for sale.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoryImages =
        ref.watch(categoryImagesProvider).valueOrNull ?? const {};
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Categories'),
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
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 10),
                Text(
                  'Failed to load categories.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(productsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (products) {
          final categories = _categoriesOf(products);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(productsProvider);
              await ref.read(productsProvider.future);
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCard(
                  title: category.name,
                  count: category.count,
                  imageUrl: categoryImages[category.name.toLowerCase()],
                  onTap: () => _openProducts(context, category.name),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openProducts(BuildContext context, String? category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductsListPage(category: category),
      ),
    );
  }

  List<_CategoryInfo> _categoriesOf(List<Product> products) {
    final byName = <String, _CategoryInfo>{};
    for (final product in products) {
      final name = product.category.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      final existing = byName[key];
      byName[key] = _CategoryInfo(
        name: existing?.name ?? name,
        count: (existing?.count ?? 0) + 1,
      );
    }
    final categories = byName.values.toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return categories;
  }
}

class _CategoryInfo {
  const _CategoryInfo({required this.name, required this.count});

  final String name;
  final int count;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.count,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final int count;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: imageUrl == null
                    ? Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(
                          Icons.category_outlined,
                          size: 42,
                          color: Color(0xFF9CA3AF),
                        ),
                      )
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(
                            Icons.category_outlined,
                            size: 42,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count product${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
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
