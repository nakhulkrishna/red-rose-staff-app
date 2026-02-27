import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/cart_item.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Review Order')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 120),
        children: [
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
          ...cart.map(
            (line) => Card(
              child: ListTile(
                title: Text(line.productName),
                subtitle: Text(
                  '${line.unitCode} • Qty ${line.quantity} • Applied QAR ${line.appliedPriceQar.toStringAsFixed(2)}',
                ),
                trailing: Text('QAR ${line.total.toStringAsFixed(2)}'),
                onTap: () => _editLine(line),
                leading: IconButton(
                  onPressed: () =>
                      ref.read(cartProvider.notifier).removeItem(line.lineId),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
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
                onPressed: isSubmitting ? null : _placeOrderAndSendBill,
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
          market: customer.marketType,
        );
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _placeOrderAndSendBill() async {
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

    final phone = (result.customerPhone ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed: ${result.orderId}. Customer phone missing.',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    final msg = Uri.encodeComponent(
      'Order ${result.orderId} placed successfully.\nTotal: QAR ${(result.amountQar ?? 0).toStringAsFixed(2)}',
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
