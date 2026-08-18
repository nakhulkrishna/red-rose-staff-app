import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/presentation/pages/order_summary_page.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/domain/entities/product_pricing.dart';
import 'package:staff_app/features/products/presentation/widgets/product_image_carousel.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  ProductUnit? _unit;
  double _quantity = 1;

  Product get _product => widget.product;

  ProductUnit? get _selectedUnit {
    if (_product.units.isEmpty) return null;
    return _unit ?? _product.units.first;
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(salesmanMarketTypeProvider);
    final unit = _selectedUnit;
    final outOfStock = _product.availableStock <= 0;
    final cartCount = ref.watch(cartProvider).length;

    final unitPrice = unit == null
        ? 0.0
        : resolveUnitOfferPrice(_product, market, unit) ??
              resolveUnitPrice(_product, market, unit);
    final total = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrderSummaryPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          ProductImageCarousel(
            imageUrls: productImages(_product),
            height: 240,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 12),
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(text: 'Code: ${_product.code}'),
                    if (_product.category.isNotEmpty)
                      _Chip(text: _product.category),
                    _Chip(
                      text: outOfStock
                          ? 'Out of stock'
                          : 'Stock ${_trim(_product.availableStock)} ${_product.baseUnit}',
                      color: outOfStock
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF047857),
                    ),
                  ],
                ),
                if (_product.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _product.description.trim(),
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Combinations',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                if (_product.units.isEmpty)
                  const Text(
                    'No unit types configured for this product.',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  )
                else
                  _PriceTable(
                    product: _product,
                    market: market,
                    selectedUnit: unit,
                    onSelect: (value) => setState(() {
                      _unit = value;
                      _quantity = 1;
                    }),
                  ),
              ],
            ),
          ),
          if (unit != null) ...[
            const SizedBox(height: 12),
            _Section(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order in ${unit.code.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _QuantityRow(
                    unit: unit,
                    quantity: _quantity,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                  const Divider(height: 24),
                  _TotalRow(
                    label: 'Unit price',
                    value: 'QAR ${unitPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 4),
                  _TotalRow(
                    label: 'Base quantity',
                    value:
                        '${_trim(_quantity * unit.multiplierToBase)} ${_product.baseUnit}',
                  ),
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'Total',
                    value: 'QAR ${total.toStringAsFixed(2)}',
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: unit == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: outOfStock ? null : () => _addToCart(unit),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    outOfStock
                        ? 'Out of stock'
                        : 'Add to Cart  •  QAR ${total.toStringAsFixed(2)}',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  void _addToCart(ProductUnit unit) {
    if (_quantity <= 0) {
      _toast('Enter a quantity greater than 0.');
      return;
    }

    final error = ref
        .read(cartProvider.notifier)
        .addItem(
          product: _product,
          unit: unit,
          quantity: _quantity,
          market: ref.read(salesmanMarketTypeProvider),
        );

    _toast(error ?? '${_product.name} added to cart.');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PriceTable extends StatelessWidget {
  const _PriceTable({
    required this.product,
    required this.market,
    required this.selectedUnit,
    required this.onSelect,
  });

  final Product product;
  final MarketType market;
  final ProductUnit? selectedUnit;
  final ValueChanged<ProductUnit> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(flex: 3, child: _Head('Unit')),
              Expanded(flex: 3, child: _Head('Contains')),
              Expanded(flex: 4, child: _Head('Price', end: true)),
            ],
          ),
        ),
        ...product.units.map((unit) {
          final price = resolveUnitPrice(product, market, unit);
          final offer = resolveUnitOfferPrice(product, market, unit);
          final selected = unit.code == selectedUnit?.code;

          return InkWell(
            onTap: () => onSelect(unit),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF111827)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: selected
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            unit.code.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${_trim(unit.multiplierToBase)} ${product.baseUnit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'QAR ${(offer ?? price).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF047857),
                          ),
                        ),
                        if (offer != null && offer < price)
                          Text(
                            'QAR ${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text, {this.end = false});

  final String text;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.unit,
    required this.quantity,
    required this.onChanged,
  });

  final ProductUnit unit;
  final double quantity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final step = unit.allowDecimal ? 0.5 : 1.0;

    return Row(
      children: [
        const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        _StepButton(
          icon: Icons.remove,
          onTap: quantity - step <= 0 ? null : () => onChanged(quantity - step),
        ),
        Container(
          width: 70,
          alignment: Alignment.center,
          child: Text(
            _trim(quantity),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        _StepButton(icon: Icons.add, onTap: () => onChanged(quantity + step)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF3F4F6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? const Color(0xFF9CA3AF) : null,
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasize ? const Color(0xFF111827) : const Color(0xFF6B7280),
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            fontSize: emphasize ? 16 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: emphasize ? 17 : 13,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? const Color(0xFF374151);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tint,
        ),
      ),
    );
  }
}

String _trim(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
