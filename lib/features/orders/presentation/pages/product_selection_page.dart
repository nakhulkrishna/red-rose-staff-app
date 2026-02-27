import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';

class ProductSelectionPage extends ConsumerStatefulWidget {
  const ProductSelectionPage({super.key, required this.marketType});

  final MarketType marketType;

  @override
  ConsumerState<ProductSelectionPage> createState() =>
      _ProductSelectionPageState();
}

class _ProductSelectionPageState extends ConsumerState<ProductSelectionPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Search product',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = products.where((p) {
                  final q = _query.toLowerCase();
                  if (q.isEmpty) return true;
                  return p.name.toLowerCase().contains(q) ||
                      p.code.toLowerCase().contains(q);
                }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF3F4F6),
                        child: product.imageUrl.isEmpty
                            ? const Icon(Icons.inventory_2_outlined)
                            : ClipOval(
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.code} • Stock ${product.availableStock.toStringAsFixed(2)} ${product.baseUnit}',
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => _addProduct(context, product),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load products: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct(BuildContext context, Product product) async {
    ProductUnit selectedUnit = product.units.first;
    final qtyController = TextEditingController(text: '1');

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(product.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProductUnit>(
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: product.units
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.code),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedUnit = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      helperText: selectedUnit.allowDecimal
                          ? 'Decimal allowed'
                          : 'Integer only',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || !context.mounted) return;
    final qty = double.tryParse(qtyController.text.trim());
    if (qty == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
      return;
    }

    final error = ref
        .read(cartProvider.notifier)
        .addItem(
          product: product,
          unit: selectedUnit,
          quantity: qty,
          market: widget.marketType,
        );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? '${product.name} added')));
  }
}
