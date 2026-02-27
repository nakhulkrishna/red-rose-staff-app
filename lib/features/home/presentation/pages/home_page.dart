import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/orders/domain/entities/sales_order.dart';
import 'package:staff_app/features/notifications/presentation/pages/order_status_notifications_page.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final fallbackFromEmail = (() {
      final email = user?.email ?? '';
      if (email.contains('@')) {
        return email.split('@').first;
      }
      return '';
    })();
    final profileName = (user?.name ?? '').trim().isNotEmpty
        ? user!.name
        : (fallbackFromEmail.isEmpty ? 'User' : fallbackFromEmail);
    final profileRegion = (user?.region ?? '').trim();

    final customers = ref.watch(customersProvider);
    final productsAsync = ref.watch(productsProvider);
    final orders = ref.watch(orderHistoryProvider).valueOrNull ?? const [];
    final totalSales = orders.fold<double>(
      0,
      (total, order) => total + order.grandTotal,
    );
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final compact = NumberFormat.compact();
    final outstanding = customers.fold<double>(
      0,
      (total, customer) => total + customer.outstandingBalance,
    );
    final productCount = productsAsync.valueOrNull?.length ?? 0;
    final inventoryBase = (productsAsync.valueOrNull ?? const []).fold<double>(
      0,
      (total, product) => total + product.availableStock,
    );
    final totalBalance = totalSales - outstanding;
    final notificationCount = orders.length;

    final statCards = [
      _SummaryStat(
        icon: Iconsax.personalcard,
        label: 'Customers',
        value: compact.format(customers.length),
        caption: 'Active',
      ),
      _SummaryStat(
        icon: Iconsax.box,
        label: 'Products',
        value: productsAsync.hasValue ? compact.format(productCount) : '...',
        caption: productsAsync.hasValue ? 'Catalog' : 'Loading',
      ),
      _SummaryStat(
        icon: Iconsax.money,
        label: 'Revenue',
        value: formatter.format(totalSales),
        caption: 'Orders',
      ),
      _SummaryStat(
        icon: Iconsax.wallet,
        label: 'Inventory',
        value: productsAsync.hasValue ? compact.format(inventoryBase) : '...',
        caption: 'Base qty',
      ),
    ];

    final recent = orders.take(4).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profileName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (profileRegion.isNotEmpty)
                        Text(
                          profileRegion,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6B7280)),
                        ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const OrderStatusNotificationsPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -3,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${notificationCount > 99 ? '99+' : notificationCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3748),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5568),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Iconsax.card, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(totalBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 34 / 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See details',
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  itemCount: statCards.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.05,
                  ),
                  itemBuilder: (context, index) =>
                      _StatTile(card: statCards[index]),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Row(
                          children: [
                            Text(
                              'Recent transactions',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_horiz),
                            ),
                          ],
                        ),
                      ),
                      if (recent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No transactions yet.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < recent.length; i++)
                          _TransactionTile(
                            order: recent[i],
                            showDivider: i != recent.length - 1,
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.card});

  final _SummaryStat card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(card.icon, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        card.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  card.value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22 / 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  card.caption,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.order, required this.showDivider});

  final SalesOrder order;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.shopping_bag_outlined, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16 / 1.3,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(order.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'QAR ${order.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF065F46),
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
