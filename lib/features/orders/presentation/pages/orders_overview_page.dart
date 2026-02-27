import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/customers/domain/entities/customer.dart';
import 'package:staff_app/features/customers/presentation/pages/customers_list_page.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/sales_order.dart';
import 'package:staff_app/features/orders/presentation/pages/order_creation_page.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';

class OrdersOverviewPage extends ConsumerStatefulWidget {
  const OrdersOverviewPage({super.key});

  @override
  ConsumerState<OrdersOverviewPage> createState() => _OrdersOverviewPageState();
}

class _OrdersOverviewPageState extends ConsumerState<OrdersOverviewPage> {
  String _query = '';
  bool _sortNewestFirst = true;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderHistoryProvider).valueOrNull ?? const [];
    final filtered =
        orders.where((order) {
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return order.customer.name.toLowerCase().contains(q) ||
              order.id.toLowerCase().contains(q);
        }).toList()..sort(
          (a, b) => _sortNewestFirst
              ? b.createdAt.compareTo(a.createdAt)
              : a.createdAt.compareTo(b.createdAt),
        );

    final today = DateTime.now();
    final todayOrders = filtered
        .where((o) => _isSameDay(o.createdAt, today))
        .toList();
    final yesterdayOrders = filtered
        .where(
          (o) =>
              _isSameDay(o.createdAt, today.subtract(const Duration(days: 1))),
        )
        .toList();
    final olderOrders = filtered
        .where(
          (o) =>
              !_isSameDay(o.createdAt, today) &&
              !_isSameDay(o.createdAt, today.subtract(const Duration(days: 1))),
        )
        .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  'Orders',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _SquareActionButton(
                  icon: Icons.swap_vert_rounded,
                  onTap: () {
                    setState(() {
                      _sortNewestFirst = !_sortNewestFirst;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SquareActionButton(
                  icon: Icons.filter_alt_outlined,
                  onTap: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
              children: [
                _OrderGroup(title: 'Today', orders: todayOrders),
                const SizedBox(height: 12),
                _OrderGroup(title: 'Yesterday', orders: yesterdayOrders),
                const SizedBox(height: 12),
                _OrderGroup(
                  title: DateFormat(
                    'd MMMM',
                  ).format(today.subtract(const Duration(days: 2))),
                  orders: olderOrders,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final selected = await Navigator.of(context).push<Customer>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const CustomersListPage(selectionMode: true),
                    ),
                  );
                  if (!context.mounted || selected == null) return;
                  ref.read(selectedCustomerProvider.notifier).state = selected;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderCreationPage(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create order'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _OrderGroup extends StatelessWidget {
  const _OrderGroup({required this.title, required this.orders});

  final String title;
  final List<SalesOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 32 / 1.5,
                ),
              ),
            ),
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No orders',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            for (var i = 0; i < orders.length; i++)
              _OrderTile(order: orders[i], showDivider: i != orders.length - 1),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.showDivider});

  final SalesOrder order;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isBig = order.grandTotal > 300;
    final status = isBig ? 'Confirmed' : 'Shipped';
    final statusColor = isBig
        ? const Color(0xFF0369A1)
        : const Color(0xFFB45309);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_outlined, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16 / 1.3,
                      ),
                    ),
                    Text(
                      '${order.items.length} Item • ${DateFormat('h:mm a').format(order.createdAt)}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '#${order.id}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}
