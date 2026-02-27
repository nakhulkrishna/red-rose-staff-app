import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

final _orderNotificationsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final firestore = ref.read(firestoreProvider);
  return Stream.fromFuture(
    _resolveSalesmanIdentifiers(
      firestore: firestore,
      uid: user.uid,
      email: user.email,
    ),
  ).asyncExpand((ids) {
    if (ids.isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }
    return firestore
        .collection('catalog_orders')
        .where('salesmanId', whereIn: ids.take(10).toList())
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => {'_id': doc.id, ...doc.data()})
              .toList();
          items.sort((a, b) {
            final ta = a['orderDate'];
            final tb = b['orderDate'];
            final da = ta is Timestamp ? ta.toDate() : DateTime(2000);
            final db = tb is Timestamp ? tb.toDate() : DateTime(2000);
            return db.compareTo(da);
          });
          return items;
        });
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

class OrderStatusNotificationsPage extends ConsumerWidget {
  const OrderStatusNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(_orderNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status Notifications')),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load notifications: $error'),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No order notifications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = orders[index];
              final orderId = (data['id'] as String?) ?? data['_id'] as String;
              final customerName =
                  (data['customerName'] as String?) ?? 'Customer';
              final orderStatus =
                  ((data['orderStatus'] as String?) ?? 'processing')
                      .toLowerCase();
              final paymentStatus =
                  ((data['paymentStatus'] as String?) ?? 'pending')
                      .toLowerCase();
              final amount = (data['amountQar'] as num?)?.toDouble() ?? 0;
              final dateRaw = data['orderDate'];
              final date = dateRaw is Timestamp
                  ? dateRaw.toDate()
                  : DateTime.now();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            orderId,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _StatusBadge(
                          label: orderStatus,
                          bg: _statusColor(orderStatus).withValues(alpha: 0.14),
                          text: _statusColor(orderStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, h:mm a').format(date),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'QAR ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        _StatusBadge(
                          label: 'Payment: $paymentStatus',
                          bg: _paymentColor(
                            paymentStatus,
                          ).withValues(alpha: 0.14),
                          text: _paymentColor(paymentStatus),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF065F46);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFB91C1C);
      case 'shipped':
      case 'confirmed':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFF92400E);
    }
  }

  Color _paymentColor(String value) {
    switch (value) {
      case 'paid':
        return const Color(0xFF065F46);
      case 'partial':
        return const Color(0xFF92400E);
      case 'failed':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF1E3A8A);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.bg,
    required this.text,
  });

  final String label;
  final Color bg;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
