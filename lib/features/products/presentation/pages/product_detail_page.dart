import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/presentation/providers/products_catalog_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({required this.productId, super.key});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late TextEditingController _qtyController;
  MarketType? _market;
  ProductUnit? _unit;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productByIdProvider(widget.productId));
    if (product == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final selectedCustomer = ref.watch(selectedCustomerProvider);
    _market ??= selectedCustomer?.marketType ?? MarketType.hyper;
    _unit ??= product.units.first;

    final quantity = double.tryParse(_qtyController.text) ?? 0;
    final unitPrice = _resolveUnitPrice(product, _market!, _unit!);
    final total = unitPrice * quantity;
    final stock = ref.watch(stockProvider)[product.id] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 36, child: Icon(Icons.image, size: 32)),
          const SizedBox(height: 12),
          Text(product.name, style: Theme.of(context).textTheme.titleLarge),
          Text(product.description),
          Text('Available Stock: ${stock.toStringAsFixed(2)} ${product.baseUnit}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<MarketType>(
            initialValue: _market,
            decoration: const InputDecoration(labelText: 'Market', border: OutlineInputBorder()),
            items: MarketType.values
                .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _market = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProductUnit>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
            items: product.units
                .map((value) => DropdownMenuItem(value: value, child: Text(value.code)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _unit = value;
                  if (!value.allowDecimal) {
                    _qtyController.text = (double.tryParse(_qtyController.text) ?? 1).toInt().toString();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity',
              helperText: _unit!.allowDecimal ? 'Decimals allowed' : 'Integers only',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit Price: ${unitPrice.toStringAsFixed(2)}'),
                  const Text('Offer Price: N/A'),
                  Text('Total Price: ${total.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _addToCart(context, product),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  double _resolveUnitPrice(Product product, MarketType market, ProductUnit unit) {
    final basePrice = product.marketPrices[market] ?? 0;
    return basePrice * unit.multiplierToBase;
  }

  void _addToCart(BuildContext context, Product product) {
    final customer = ref.read(selectedCustomerProvider);
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select customer first from Customers screen.')),
      );
      return;
    }

    final quantity = double.tryParse(_qtyController.text);
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    final error = ref.read(cartProvider.notifier).addItem(
          product: product,
          unit: _unit!,
          quantity: quantity,
          market: _market!,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Product added to cart.')),
    );

    if (error == null) {
      Navigator.of(context).pop();
    }
  }
}
