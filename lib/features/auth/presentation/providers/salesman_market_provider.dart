import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

String resolveSalesmanMarketKey(String? salesMarketAccess) {
  final raw = (salesMarketAccess ?? '').trim().toLowerCase();
  if (raw == 'hyper_only' || raw == 'hyper') return 'hyper_market';
  return 'local_market'; // local_only, both, null, unknown => local
}

class SalesmanMarketContext {
  const SalesmanMarketContext({
    required this.salesMarketAccess,
    required this.salesMarketKey,
    required this.marketType,
  });

  final String? salesMarketAccess;
  final String salesMarketKey;
  final MarketType marketType;

  String get priceModeLabel => marketType.label;
}

final salesmanMarketContextProvider = FutureProvider<SalesmanMarketContext>((
  ref,
) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) {
    return const SalesmanMarketContext(
      salesMarketAccess: null,
      salesMarketKey: 'local_market',
      marketType: MarketType.local,
    );
  }

  final firestore = ref.read(firestoreProvider);
  final staff = firestore.collection('catalog_staff_salesmen');
  final firebaseUser = ref.read(firebaseAuthProvider).currentUser;

  DocumentSnapshot<Map<String, dynamic>>? match;

  final byUid = await staff.where('uid', isEqualTo: user.uid).limit(1).get();
  if (byUid.docs.isNotEmpty) {
    match = byUid.docs.first;
  }

  if (match == null) {
    final email = (user.email).trim();
    if (email.isNotEmpty) {
      final byEmail = await staff
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (byEmail.docs.isNotEmpty) {
        match = byEmail.docs.first;
      }
    }
  }

  if (match == null) {
    final displayName = (firebaseUser?.displayName ?? '').trim();
    if (displayName.isNotEmpty) {
      final byName = await staff
          .where('name', isEqualTo: displayName)
          .limit(1)
          .get();
      if (byName.docs.isNotEmpty) {
        match = byName.docs.first;
      }
    }
  }

  if (match == null) {
    return const SalesmanMarketContext(
      salesMarketAccess: null,
      salesMarketKey: 'local_market',
      marketType: MarketType.local,
    );
  }

  final data = match.data() ?? const <String, dynamic>{};
  final role = ((data['role'] as String?) ?? '').trim().toLowerCase();
  if (role.contains('admin')) {
    return const SalesmanMarketContext(
      salesMarketAccess: 'admin_forced_local',
      salesMarketKey: 'local_market',
      marketType: MarketType.local,
    );
  }

  final access = (data['salesMarketAccess'] as String?)?.trim();
  final key = resolveSalesmanMarketKey(access);
  return SalesmanMarketContext(
    salesMarketAccess: access,
    salesMarketKey: key,
    marketType: key == 'hyper_market' ? MarketType.hyper : MarketType.local,
  );
});

final salesmanMarketTypeProvider = Provider<MarketType>((ref) {
  final context = ref.watch(salesmanMarketContextProvider).valueOrNull;
  return context?.marketType ?? MarketType.local;
});

final salesmanMarketKeyProvider = Provider<String>((ref) {
  final context = ref.watch(salesmanMarketContextProvider).valueOrNull;
  return context?.salesMarketKey ?? 'local_market';
});
