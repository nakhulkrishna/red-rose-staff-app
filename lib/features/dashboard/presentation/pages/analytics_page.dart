import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

enum AnalyticsRange { today, week, month, custom }

class AnalyticsFilter {
  const AnalyticsFilter({
    this.range = AnalyticsRange.week,
    this.category = 'All',
    this.paymentStatus = 'All',
    this.customerId = 'All',
    this.customStart,
    this.customEnd,
  });

  final AnalyticsRange range;
  final String category;
  final String paymentStatus;
  final String customerId;
  final DateTime? customStart;
  final DateTime? customEnd;

  AnalyticsFilter copyWith({
    AnalyticsRange? range,
    String? category,
    String? paymentStatus,
    String? customerId,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return AnalyticsFilter(
      range: range ?? this.range,
      category: category ?? this.category,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      customerId: customerId ?? this.customerId,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }
}

class AnalyticsFilterController extends StateNotifier<AnalyticsFilter> {
  AnalyticsFilterController() : super(const AnalyticsFilter());

  void setRange(AnalyticsRange value) => state = state.copyWith(range: value);
  void setCategory(String value) => state = state.copyWith(category: value);
  void setPaymentStatus(String value) =>
      state = state.copyWith(paymentStatus: value);
  void setCustomerId(String value) => state = state.copyWith(customerId: value);
  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      range: AnalyticsRange.custom,
      customStart: DateTime(start.year, start.month, start.day),
      customEnd: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  void reset() => state = const AnalyticsFilter();
}

final analyticsFilterProvider =
    StateNotifierProvider<AnalyticsFilterController, AnalyticsFilter>((ref) {
      return AnalyticsFilterController();
    });

final _ordersRawProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value(const []);
  final firestore = ref.read(firestoreProvider);

  return Stream.fromFuture(
    _resolveSalesmanIdentifiers(
      firestore: firestore,
      uid: authUser.uid,
      email: authUser.email,
    ),
  ).asyncExpand((ids) {
    if (ids.isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }
    return firestore
        .collection('catalog_orders')
        .where('salesmanId', whereIn: ids.take(10).toList())
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'_id': doc.id, ...doc.data()})
              .toList(),
        );
  });
});

final _staffProfileProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) async* {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) {
    yield const {};
    return;
  }
  final firestore = ref.read(firestoreProvider);

  final byUid = await firestore
      .collection('catalog_staff_salesmen')
      .where('uid', isEqualTo: authUser.uid)
      .limit(1)
      .get();
  if (byUid.docs.isNotEmpty) {
    yield byUid.docs.first.data();
    return;
  }

  if (authUser.email.isNotEmpty) {
    final byEmail = await firestore
        .collection('catalog_staff_salesmen')
        .where('email', isEqualTo: authUser.email)
        .limit(1)
        .get();
    if (byEmail.docs.isNotEmpty) {
      yield byEmail.docs.first.data();
      return;
    }
  }

  final byDocId = await firestore
      .collection('catalog_staff_salesmen')
      .doc(authUser.uid)
      .get();
  if (byDocId.exists) {
    yield byDocId.data() ?? const {};
    return;
  }

  yield const {};
});

final _categoryByProductCodeProvider = StreamProvider<Map<String, String>>((
  ref,
) {
  final firestore = ref.read(firestoreProvider);
  return firestore.collection('catalog_products').snapshots().map((snapshot) {
    final map = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final code = (data['productCode'] as String?) ?? '';
      if (code.isEmpty) continue;
      final category = (data['category'] is Map<String, dynamic>)
          ? ((data['category'] as Map<String, dynamic>)['name'] as String?) ??
                'General'
          : 'General';
      map[code] = category;
    }
    return map;
  });
});

Future<List<String>> _resolveSalesmanIdentifiers({
  required FirebaseFirestore firestore,
  required String uid,
  required String email,
}) async {
  final ids = <String>{uid};
  final staff = firestore.collection('catalog_staff_salesmen');

  final byUid = await staff.where('uid', isEqualTo: uid).limit(1).get();
  for (final doc in byUid.docs) {
    ids.add(doc.id);
    final code = (doc.data()['id'] as String?)?.trim() ?? '';
    if (code.isNotEmpty) ids.add(code);
  }

  if (email.isNotEmpty) {
    final byEmail = await staff.where('email', isEqualTo: email).limit(1).get();
    for (final doc in byEmail.docs) {
      ids.add(doc.id);
      final code = (doc.data()['id'] as String?)?.trim() ?? '';
      if (code.isNotEmpty) ids.add(code);
    }
  }

  final byDoc = await staff.doc(uid).get();
  if (byDoc.exists) {
    ids.add(byDoc.id);
    final code = (byDoc.data()?['id'] as String?)?.trim() ?? '';
    if (code.isNotEmpty) ids.add(code);
  }

  return ids.where((id) => id.trim().isNotEmpty).toList();
}

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsync = ref.watch(_ordersRawProvider);
    final staffAsync = ref.watch(_staffProfileProvider);
    final categoryMap =
        ref.watch(_categoryByProductCodeProvider).valueOrNull ?? const {};
    final filter = ref.watch(analyticsFilterProvider);
    final customers = ref.watch(customersProvider);

    final compact = Theme.of(context).textTheme.copyWith(
      bodyLarge: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.22),
      bodyMedium: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontSize: 12.5, height: 1.2),
      bodySmall: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.18),
      titleMedium: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontSize: 14),
      titleSmall: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontSize: 13),
      labelLarge: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontSize: 12),
    );

    return Theme(
      data: Theme.of(context).copyWith(textTheme: compact),
      child: SafeArea(
        child: rawAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load analytics: $error'),
            ),
          ),
          data: (rawOrders) {
            final orders = rawOrders
                .map((e) => _OrderView.fromMap(e, categoryMap))
                .toList();
            final dataset = _AnalyticsDataset.build(
              allOrders: orders,
              filter: filter,
              customersCount: customers.length,
              targetQar:
                  (staffAsync.valueOrNull?['monthlyTargetQar'] as num?)
                      ?.toDouble() ??
                  0,
              staffDealsClosed:
                  (staffAsync.valueOrNull?['dealsClosed'] as num?)?.toInt() ??
                  0,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              children: [
                _AnalyticsHero(dataset: dataset, filter: filter),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _AnalyticsFilters(
                  filter: filter,
                  categories: dataset.availableCategories,
                  customers: dataset.availableCustomers,
                  onReset: () =>
                      ref.read(analyticsFilterProvider.notifier).reset(),
                  onRange: (v) =>
                      ref.read(analyticsFilterProvider.notifier).setRange(v),
                  onCategory: (v) =>
                      ref.read(analyticsFilterProvider.notifier).setCategory(v),
                  onPayment: (v) => ref
                      .read(analyticsFilterProvider.notifier)
                      .setPaymentStatus(v),
                  onCustomer: (v) => ref
                      .read(analyticsFilterProvider.notifier)
                      .setCustomerId(v),
                  onCustomRange: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 1),
                      initialDateRange: DateTimeRange(
                        start:
                            filter.customStart ??
                            now.subtract(const Duration(days: 7)),
                        end: filter.customEnd ?? now,
                      ),
                    );
                    if (picked == null) return;
                    ref
                        .read(analyticsFilterProvider.notifier)
                        .setCustomRange(picked.start, picked.end);
                  },
                ),
                const SizedBox(height: 10),
                if (dataset.filteredOrders.isEmpty)
                  _AnalyticsEmptyState(
                    onReset: () =>
                        ref.read(analyticsFilterProvider.notifier).reset(),
                  )
                else ...[
                  _KpiGrid(
                    dataset: dataset,
                    onTapOrders: () => _showOrdersSheet(
                      context,
                      dataset.filteredOrders,
                      title: 'Filtered Orders',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PerformanceCard(dataset: dataset),
                  const SizedBox(height: 10),
                  _TrendCard(dataset: dataset),
                  const SizedBox(height: 10),
                  _CategoryCard(dataset: dataset),
                  const SizedBox(height: 10),
                  _TopProductsCard(
                    dataset: dataset,
                    onTapProduct: (product) => _showOrdersSheet(
                      context,
                      dataset.filteredOrders
                          .where(
                            (o) => o.items.any((i) => i.productName == product),
                          )
                          .toList(),
                      title: 'Orders for $product',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CustomerInsightsCard(
                    dataset: dataset,
                    onTapCustomer: (customerId) => _showOrdersSheet(
                      context,
                      dataset.filteredOrders
                          .where((o) => o.customerId == customerId)
                          .toList(),
                      title: 'Customer Orders',
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _showOrdersSheet(
    BuildContext context,
    List<_OrderView> orders, {
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(child: Text('No matching orders'))
                      : ListView.separated(
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              title: Text(order.id),
                              subtitle: Text(
                                '${order.customerName} • ${DateFormat('dd MMM, h:mm a').format(order.orderDate)}',
                              ),
                              trailing: Text(
                                'QAR ${order.amountQar.toStringAsFixed(2)}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _analyticsCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: const [
      BoxShadow(color: Color(0x0F0F172A), blurRadius: 14, offset: Offset(0, 6)),
    ],
  );
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({required this.dataset, required this.filter});

  final _AnalyticsDataset dataset;
  final AnalyticsFilter filter;

  @override
  Widget build(BuildContext context) {
    final periodLabel = switch (filter.range) {
      AnalyticsRange.today => 'Today',
      AnalyticsRange.week => 'This Week',
      AnalyticsRange.month => 'This Month',
      AnalyticsRange.custom => 'Custom Period',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  periodLabel,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  title: 'Total Sales',
                  value:
                      'QAR ${dataset.filteredOrders.fold<double>(0, (t, e) => t + e.amountQar).toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _heroStat(
                  title: 'Orders',
                  value: dataset.filteredOrders.length.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsFilters extends StatelessWidget {
  const _AnalyticsFilters({
    required this.filter,
    required this.categories,
    required this.customers,
    required this.onReset,
    required this.onRange,
    required this.onCategory,
    required this.onPayment,
    required this.onCustomer,
    required this.onCustomRange,
  });

  final AnalyticsFilter filter;
  final List<String> categories;
  final List<MapEntry<String, String>> customers;
  final VoidCallback onReset;
  final ValueChanged<AnalyticsRange> onRange;
  final ValueChanged<String> onCategory;
  final ValueChanged<String> onPayment;
  final ValueChanged<String> onCustomer;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _analyticsCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Quick Filters',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onReset,
                child: const Text('Reset'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: AnalyticsRange.values
                .map(
                  (range) => ChoiceChip(
                    label: Text(_rangeLabel(range)),
                    selected: filter.range == range,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    selectedColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: filter.range == range
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => onRange(range),
                  ),
                )
                .toList(),
          ),
          if (filter.range == AnalyticsRange.custom) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onCustomRange,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${DateFormat('dd MMM yyyy').format(filter.customStart ?? DateTime.now())} - ${DateFormat('dd MMM yyyy').format(filter.customEnd ?? DateTime.now())}',
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  hint: 'Category',
                  value: filter.category,
                  items: ['All', ...categories],
                  onChanged: onCategory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  hint: 'Payment',
                  value: filter.paymentStatus,
                  items: const ['All', 'pending', 'paid', 'partial', 'failed'],
                  onChanged: onPayment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dropdown(
            hint: 'Customer',
            value: filter.customerId,
            items: ['All', ...customers.map((e) => e.key)],
            labels: {for (final e in customers) e.key: e.value},
            onChanged: onCustomer,
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String value,
    required List<String> items,
    Map<String, String>? labels,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(labels?[item] ?? item),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _rangeLabel(AnalyticsRange range) {
    switch (range) {
      case AnalyticsRange.today:
        return 'Today';
      case AnalyticsRange.week:
        return 'Week';
      case AnalyticsRange.month:
        return 'Month';
      case AnalyticsRange.custom:
        return 'Custom';
    }
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dataset, required this.onTapOrders});

  final _AnalyticsDataset dataset;
  final VoidCallback onTapOrders;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      name: 'QAR',
      symbol: 'QAR ',
      decimalDigits: 2,
    );
    final kpis = [
      ('Today Sales', money.format(dataset.todaySales)),
      ('This Week Sales', money.format(dataset.weekSales)),
      ('This Month Sales', money.format(dataset.monthSales)),
      ('Orders Count', dataset.filteredOrders.length.toString()),
      ('Avg Order Value', money.format(dataset.avgOrderValue)),
      ('Collection Paid', money.format(dataset.paidAmount)),
    ];
    return GridView.builder(
      itemCount: kpis.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final item = kpis[index];
        return InkWell(
          onTap: onTapOrders,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: _analyticsCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No orders for selected filters',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try changing the date range or clear filters to see your analytics.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.dataset});

  final _AnalyticsDataset dataset;

  @override
  Widget build(BuildContext context) {
    final progress = dataset.targetQar > 0
        ? (dataset.monthSales / dataset.targetQar).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target vs Achieved',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F2937)),
          ),
          const SizedBox(height: 6),
          Text(
            'QAR ${dataset.monthSales.toStringAsFixed(2)} / QAR ${dataset.targetQar.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _pill('Deals Closed', dataset.dealsClosed.toString()),
              _pill('Active Customers', dataset.activeCustomers.toString()),
              _pill('New Customers', dataset.newCustomers.toString()),
              _pill('Pending Follow-ups', dataset.pendingFollowups.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.dataset});

  final _AnalyticsDataset dataset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales & Orders Trends',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _SalesLinePainter(points: dataset.salesTrendPoints),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _OrdersBarPainter(points: dataset.orderTrendPoints),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.dataset});
  final _AnalyticsDataset dataset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category-wise Sales',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: dataset.categorySalesValues.values.toList(),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dataset.categorySalesValues.entries
                        .take(5)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${e.key}: QAR ${e.value.toStringAsFixed(2)}',
                            ),
                          ),
                        )
                        .toList(),
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

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.dataset, required this.onTapProduct});
  final _AnalyticsDataset dataset;
  final ValueChanged<String> onTapProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...dataset.topProducts.entries
              .take(5)
              .map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  subtitle: Text('Qty ${entry.value.qty.toStringAsFixed(2)}'),
                  trailing: Text(
                    'QAR ${entry.value.amount.toStringAsFixed(2)}',
                  ),
                  onTap: () => onTapProduct(entry.key),
                ),
              ),
        ],
      ),
    );
  }
}

class _CustomerInsightsCard extends StatelessWidget {
  const _CustomerInsightsCard({
    required this.dataset,
    required this.onTapCustomer,
  });
  final _AnalyticsDataset dataset;
  final ValueChanged<String> onTapCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _analyticsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Insights',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...dataset.topCustomers
              .take(5)
              .map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  trailing: Text(
                    'QAR ${dataset.customerAmounts[entry.key]!.toStringAsFixed(2)}',
                  ),
                  onTap: () => onTapCustomer(entry.key),
                ),
              ),
          const Divider(height: 18),
          Text('Repeat Customers: ${dataset.repeatCustomers}'),
          Text('New Customers: ${dataset.newCustomers}'),
          Text('Pending Follow-ups: ${dataset.pendingFollowups}'),
        ],
      ),
    );
  }
}

class _OrderView {
  _OrderView({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amountQar,
    required this.paymentStatus,
    required this.orderDate,
    required this.items,
  });

  factory _OrderView.fromMap(
    Map<String, dynamic> map,
    Map<String, String> categoryByCode,
  ) {
    final rawItems =
        (map['items'] as List?)?.whereType<Map>().toList() ?? const [];
    final items = rawItems.map((raw) {
      final m = raw.cast<String, dynamic>();
      final code = (m['productCode'] as String?) ?? '';
      return _OrderItemView(
        productName: (m['productName'] as String?) ?? 'Product',
        productCode: code,
        qty: (m['qty'] as num?)?.toDouble() ?? 0,
        lineTotal: (m['lineTotalQar'] as num?)?.toDouble() ?? 0,
        category:
            (m['category'] as String?) ?? (categoryByCode[code] ?? 'General'),
      );
    }).toList();
    final ts = map['orderDate'];
    DateTime date = DateTime.now();
    if (ts is Timestamp) date = ts.toDate();
    return _OrderView(
      id: (map['id'] as String?) ?? (map['_id'] as String?) ?? '',
      customerId: (map['customerId'] as String?) ?? '',
      customerName: (map['customerName'] as String?) ?? 'Customer',
      amountQar: (map['amountQar'] as num?)?.toDouble() ?? 0,
      paymentStatus: (map['paymentStatus'] as String?) ?? 'pending',
      orderDate: date,
      items: items,
    );
  }

  final String id;
  final String customerId;
  final String customerName;
  final double amountQar;
  final String paymentStatus;
  final DateTime orderDate;
  final List<_OrderItemView> items;
}

class _OrderItemView {
  _OrderItemView({
    required this.productName,
    required this.productCode,
    required this.qty,
    required this.lineTotal,
    required this.category,
  });

  final String productName;
  final String productCode;
  final double qty;
  final double lineTotal;
  final String category;
}

class _TopProductMetrics {
  _TopProductMetrics({required this.qty, required this.amount});
  double qty;
  double amount;
}

class _AnalyticsDataset {
  _AnalyticsDataset({
    required this.filteredOrders,
    required this.todaySales,
    required this.weekSales,
    required this.monthSales,
    required this.avgOrderValue,
    required this.paidAmount,
    required this.targetQar,
    required this.dealsClosed,
    required this.activeCustomers,
    required this.newCustomers,
    required this.pendingFollowups,
    required this.salesTrendPoints,
    required this.orderTrendPoints,
    required this.categorySalesValues,
    required this.topProducts,
    required this.topCustomers,
    required this.customerAmounts,
    required this.repeatCustomers,
    required this.availableCategories,
    required this.availableCustomers,
  });

  final List<_OrderView> filteredOrders;
  final double todaySales;
  final double weekSales;
  final double monthSales;
  final double avgOrderValue;
  final double paidAmount;
  final double targetQar;
  final int dealsClosed;
  final int activeCustomers;
  final int newCustomers;
  final int pendingFollowups;
  final List<double> salesTrendPoints;
  final List<double> orderTrendPoints;
  final Map<String, double> categorySalesValues;
  final Map<String, _TopProductMetrics> topProducts;
  final List<MapEntry<String, String>> topCustomers;
  final Map<String, double> customerAmounts;
  final int repeatCustomers;
  final List<String> availableCategories;
  final List<MapEntry<String, String>> availableCustomers;

  static _AnalyticsDataset build({
    required List<_OrderView> allOrders,
    required AnalyticsFilter filter,
    required int customersCount,
    required double targetQar,
    required int staffDealsClosed,
  }) {
    final now = DateTime.now();
    bool inRange(DateTime date) {
      final startToday = DateTime(now.year, now.month, now.day);
      switch (filter.range) {
        case AnalyticsRange.today:
          return !date.isBefore(startToday);
        case AnalyticsRange.week:
          return !date.isBefore(startToday.subtract(const Duration(days: 6)));
        case AnalyticsRange.month:
          return !date.isBefore(DateTime(now.year, now.month, 1));
        case AnalyticsRange.custom:
          final s =
              filter.customStart ??
              startToday.subtract(const Duration(days: 30));
          final e = filter.customEnd ?? now;
          return !date.isBefore(s) && !date.isAfter(e);
      }
    }

    final availableCategories =
        allOrders.expand((o) => o.items.map((i) => i.category)).toSet().toList()
          ..sort();
    final availableCustomersMap = <String, String>{};
    for (final o in allOrders) {
      if (o.customerId.isNotEmpty) {
        availableCustomersMap[o.customerId] = o.customerName;
      }
    }
    final availableCustomers = availableCustomersMap.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    final filtered = allOrders.where((order) {
      if (!inRange(order.orderDate)) return false;
      if (filter.paymentStatus != 'All' &&
          order.paymentStatus != filter.paymentStatus) {
        return false;
      }
      if (filter.customerId != 'All' && order.customerId != filter.customerId) {
        return false;
      }
      if (filter.category != 'All' &&
          !order.items.any((i) => i.category == filter.category)) {
        return false;
      }
      return true;
    }).toList();

    double periodSales(List<_OrderView> source, Duration duration) {
      final start = now.subtract(duration);
      return source
          .where((o) => o.orderDate.isAfter(start))
          .fold<double>(0, (total, o) => total + o.amountQar);
    }

    final todaySales = periodSales(allOrders, const Duration(days: 1));
    final weekSales = periodSales(allOrders, const Duration(days: 7));
    final monthSales = allOrders
        .where(
          (o) => o.orderDate.year == now.year && o.orderDate.month == now.month,
        )
        .fold<double>(0, (total, o) => total + o.amountQar);
    final filteredSales = filtered.fold<double>(
      0,
      (total, o) => total + o.amountQar,
    );
    final avgOrderValue = filtered.isEmpty
        ? 0.0
        : filteredSales / filtered.length;
    final paidAmount = filtered
        .where((o) => o.paymentStatus.toLowerCase() == 'paid')
        .fold<double>(0, (total, o) => total + o.amountQar);
    final activeCustomers = filtered
        .map((o) => o.customerId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .length;

    final customerAmounts = <String, double>{};
    final customerNames = <String, String>{};
    for (final o in filtered) {
      if (o.customerId.isEmpty) continue;
      customerAmounts[o.customerId] =
          (customerAmounts[o.customerId] ?? 0) + o.amountQar;
      customerNames[o.customerId] = o.customerName;
    }
    final sortedCustomers = customerAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCustomers = sortedCustomers
        .map((e) => MapEntry(e.key, customerNames[e.key] ?? 'Customer'))
        .toList();

    final topProducts = <String, _TopProductMetrics>{};
    final categorySales = <String, double>{};
    for (final order in filtered) {
      for (final item in order.items) {
        final metrics = topProducts.putIfAbsent(
          item.productName,
          () => _TopProductMetrics(qty: 0, amount: 0),
        );
        metrics.qty += item.qty;
        metrics.amount += item.lineTotal;
        categorySales[item.category] =
            (categorySales[item.category] ?? 0) + item.lineTotal;
      }
    }
    final sortedProducts = topProducts.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    final rankedProducts = {for (final e in sortedProducts) e.key: e.value};

    final salesTrend = <double>[];
    final orderTrend = <double>[];
    final days = filter.range == AnalyticsRange.month ? 30 : 7;
    for (var i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayOrders = filtered
          .where(
            (o) =>
                o.orderDate.isAfter(dayStart) && o.orderDate.isBefore(dayEnd),
          )
          .toList();
      salesTrend.add(
        dayOrders.fold<double>(0, (total, o) => total + o.amountQar),
      );
      orderTrend.add(dayOrders.length.toDouble());
    }

    final firstOrderByCustomer = <String, DateTime>{};
    for (final order in allOrders) {
      if (order.customerId.isEmpty) continue;
      final first = firstOrderByCustomer[order.customerId];
      if (first == null || order.orderDate.isBefore(first)) {
        firstOrderByCustomer[order.customerId] = order.orderDate;
      }
    }
    final rangeStart = filter.range == AnalyticsRange.month
        ? DateTime(now.year, now.month, 1)
        : DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6));
    final newCustomers = firstOrderByCustomer.values
        .where((d) => d.isAfter(rangeStart))
        .length;
    final repeatCustomers = math.max(0, activeCustomers - newCustomers);

    final pendingFollowups = filtered
        .where((o) => o.paymentStatus == 'pending')
        .length;

    return _AnalyticsDataset(
      filteredOrders: filtered,
      todaySales: todaySales,
      weekSales: weekSales,
      monthSales: monthSales,
      avgOrderValue: avgOrderValue,
      paidAmount: paidAmount,
      targetQar: targetQar,
      dealsClosed: staffDealsClosed == 0 ? filtered.length : staffDealsClosed,
      activeCustomers: activeCustomers == 0 ? customersCount : activeCustomers,
      newCustomers: newCustomers,
      pendingFollowups: pendingFollowups,
      salesTrendPoints: salesTrend,
      orderTrendPoints: orderTrend,
      categorySalesValues: categorySales,
      topProducts: rankedProducts,
      topCustomers: topCustomers,
      customerAmounts: customerAmounts,
      repeatCustomers: repeatCustomers,
      availableCategories: availableCategories,
      availableCustomers: availableCustomers,
    );
  }
}

class _SalesLinePainter extends CustomPainter {
  _SalesLinePainter({required this.points});
  final List<double> points;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bg);
    }
    if (points.isEmpty) return;
    final minV = points.reduce(math.min);
    final maxV = points.reduce(math.max);
    final range = (maxV - minV).abs() < 1 ? 1 : (maxV - minV);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * (size.width / math.max(1, points.length - 1));
      final y =
          size.height - (((points[i] - minV) / range) * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1F2937)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SalesLinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _OrdersBarPainter extends CustomPainter {
  _OrdersBarPainter({required this.points});
  final List<double> points;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxV = points.reduce(math.max);
    final barW = size.width / (points.length * 1.8);
    for (var i = 0; i < points.length; i++) {
      final h = maxV == 0 ? 0.0 : (points[i] / maxV) * size.height;
      final x = i * (barW * 1.8);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, Paint()..color = const Color(0xFF9CA3AF));
    }
  }

  @override
  bool shouldRepaint(covariant _OrdersBarPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values});
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final colors = [
      const Color(0xFF1F2937),
      const Color(0xFF475569),
      const Color(0xFF64748B),
      const Color(0xFF94A3B8),
      const Color(0xFFCBD5E1),
    ];
    var start = -math.pi / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: math.min(size.width, size.height) / 2 - 4,
    );
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 18
          ..style = PaintingStyle.stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}
