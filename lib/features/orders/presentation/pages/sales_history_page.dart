import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/orders/domain/entities/sales_order.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';

class SalesHistoryPage extends ConsumerWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderHistoryProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet.'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text(order.id),
                  subtitle: Text(
                    '${order.customer.name} • ${DateFormat('dd MMM yyyy').format(order.createdAt)}',
                  ),
                  trailing: Text(order.grandTotal.toStringAsFixed(2)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SalesOrderDetailPage(order: order)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class SalesOrderDetailPage extends StatelessWidget {
  final SalesOrder order;

  const SalesOrderDetailPage({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(order.customer.name, style: Theme.of(context).textTheme.titleMedium),
          Text(order.customer.phone),
          const Divider(height: 24),
          ...order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.productName),
              subtitle: Text('${item.unitCode} x ${item.quantity}'),
              trailing: Text(item.total.toStringAsFixed(2)),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Subtotal'), Text(order.subtotal.toStringAsFixed(2))],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Discount'), Text(order.discount.toStringAsFixed(2))],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text('Grand Total'), Text(order.grandTotal.toStringAsFixed(2))],
          ),
        ],
      ),
    );
  }
}
