import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/cart_item.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/shared/providers/whatsapp_order_number_provider.dart';
import 'package:staff_app/shared/widgets/price_mode_banner.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderSummaryPage extends ConsumerStatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  ConsumerState<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends ConsumerState<OrderSummaryPage> {
  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(selectedCustomerProvider);
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(orderSubtotalProvider);
    final discount = ref.watch(orderDiscountProvider);
    final grandTotal = ref.watch(orderGrandTotalProvider);
    final submitState = ref.watch(orderSubmissionControllerProvider);
    final isSubmitting = submitState.isLoading;
    final marketContext = ref.watch(salesmanMarketContextProvider).valueOrNull;
    final priceModeLabel = marketContext?.priceModeLabel ?? 'Local Market';

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 120),
        children: [
          PriceModeBanner(label: priceModeLabel),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(customer?.name ?? 'No customer selected'),
                Text(customer?.phone ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (cart.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 36,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Go back and add products to place this order.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...cart.map(
              (line) => _OrderLineCard(
                line: line,
                onEdit: () => _editLine(line),
                onRemove: () =>
                    ref.read(cartProvider.notifier).removeItem(line.lineId),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Subtotal', 'QAR ${subtotal.toStringAsFixed(2)}'),
            _row('Discount', 'QAR ${discount.toStringAsFixed(2)}'),
            _row(
              'Grand Total',
              'QAR ${grandTotal.toStringAsFixed(2)}',
              bold: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.isEmpty || isSubmitting
                    ? null
                    : _placeOrderAndSendBill,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Place Order & Send Bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editLine(CartItem line) async {
    final product = ref.read(productByIdProvider(line.productId));
    final customer = ref.read(selectedCustomerProvider);
    final marketType = ref.read(salesmanMarketTypeProvider);
    if (product == null || customer == null) return;

    ProductUnit unit = product.units.firstWhere((u) => u.code == line.unitCode);
    final qtyController = TextEditingController(text: line.quantity.toString());
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Line'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ProductUnit>(
                  initialValue: unit,
                  items: product.units
                      .map(
                        (u) => DropdownMenuItem(value: u, child: Text(u.code)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => unit = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (save != true || !mounted) return;
    final qty = double.tryParse(qtyController.text.trim());
    if (qty == null) return;
    final error = ref
        .read(cartProvider.notifier)
        .updateItem(
          lineId: line.lineId,
          product: product,
          unit: unit,
          quantity: qty,
          market: marketType,
        );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  String _buildOrderMessage({
    required String orderId,
    required String salesmanName,
    required String customerName,
    required List<CartItem> items,
    required double totalQar,
  }) {
    String qty(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    final buffer = StringBuffer()
      ..writeln('*ORDER SUMMARY*')
      ..writeln('Order ID: $orderId')
      ..writeln('Salesman: $salesmanName')
      ..writeln(
        'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
      )
      ..writeln('--------------------');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      buffer
        ..writeln('${i + 1}. Product: ${item.productName}')
        ..writeln('   Qty Type: ${item.unitCode}')
        ..writeln('   Qty: ${qty(item.quantity)}')
        ..writeln('   Price: QAR ${item.total.toStringAsFixed(2)}');
    }

    buffer
      ..writeln('--------------------')
      ..writeln('Customer Name: $customerName')
      ..write('Total Price: QAR ${totalQar.toStringAsFixed(2)}');

    return buffer.toString();
  }

  Future<void> _placeOrderAndSendBill() async {
    // Captured before submitting: submitOrder() clears the cart.
    final items = List<CartItem>.from(ref.read(cartProvider));
    final customerName = ref.read(selectedCustomerProvider)?.name ?? '-';
    final salesmanName = ref.read(authStateProvider).valueOrNull?.name ?? '-';

    final result = await ref
        .read(orderSubmissionControllerProvider.notifier)
        .submitOrder();
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? 'Order failed')));
      return;
    }

    final phone = await ref.read(whatsappOrderNumberProvider.future);
    if (!mounted) return;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed: ${result.orderId}. WhatsApp order number is not '
            'configured in the dashboard.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    final msg = Uri.encodeComponent(
      _buildOrderMessage(
        orderId: result.orderId ?? '-',
        salesmanName: salesmanName,
        customerName: customerName,
        items: items,
        totalQar: result.amountQar ?? 0,
      ),
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed: ${result.orderId}. Could not open WhatsApp.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Order placed: ${result.orderId}')));
    Navigator.of(context).pop();
  }
}

class _OrderLineCard extends StatelessWidget {
  const _OrderLineCard({
    required this.line,
    required this.onEdit,
    required this.onRemove,
  });

  final CartItem line;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'QAR ${line.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge('Unit: ${line.unitCode}'),
                _badge('Qty: ${line.quantity}'),
                _badge('Price: ${line.appliedPriceQar.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFB91C1C),
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
