import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:staff_app/shared/widgets/app_scaffold.dart';
import 'package:staff_app/shared/widgets/price_mode_banner.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final priceModeLabel =
        ref.watch(salesmanMarketContextProvider).valueOrNull?.priceModeLabel ??
        'Local Market';

    return AppScaffold(
      title: 'Products',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: PriceModeBanner(label: priceModeLabel),
          ),
          Expanded(
            child: products.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.id),
                    );
                  },
                );
              },
              error: (error, _) => Center(child: Text('Error: $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
