import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/core/config/firestore_collections.dart';
import 'package:staff_app/features/customers/domain/entities/customer.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final firestore = ref.read(firestoreProvider);
  return firestore.collection(FirestoreCollections.customers).snapshots().map((
    snapshot,
  ) {
    final customers = snapshot.docs
        .where((doc) => (doc.data()['status'] as String? ?? '') == 'active')
        .map((doc) => _toCustomer(doc))
        .toList();
    customers.sort((a, b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return customers;
  });
});

final customersProvider = Provider<List<Customer>>((ref) {
  return ref.watch(customersStreamProvider).valueOrNull ?? const [];
});

final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

Customer _toCustomer(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data() ?? const <String, dynamic>{};
  final name =
      (data['name'] as String?) ??
      (data['customerName'] as String?) ??
      (data['companyName'] as String?) ??
      'Unknown';
  final phone =
      (data['phone'] as String?) ??
      (data['whatsapp'] as String?) ??
      (data['mobile'] as String?) ??
      (data['phoneNumber'] as String?) ??
      '';
  final marketRaw =
      ((data['marketType'] as String?) ??
              (data['market'] as String?) ??
              (data['marketKey'] as String?) ??
              '')
          .toLowerCase();
  final marketType = marketRaw.contains('local')
      ? MarketType.local
      : MarketType.hyper;
  final outstanding =
      (data['outstandingBalance'] as num?)?.toDouble() ??
      (data['balance'] as num?)?.toDouble() ??
      0.0;

  return Customer(
    id: (data['id'] as String?) ?? doc.id,
    name: name,
    phone: phone,
    marketType: marketType,
    outstandingBalance: outstanding,
  );
}
