import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:staff_app/shared/widgets/app_scaffold.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return AppScaffold(
      title: 'Products',
      body: products.when(
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
    );
  }
}
