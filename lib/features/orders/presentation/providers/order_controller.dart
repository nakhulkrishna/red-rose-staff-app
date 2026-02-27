import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:staff_app/features/customers/domain/entities/customer.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/cart_item.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/domain/entities/sales_order.dart';
import 'package:staff_app/features/products/data/models/product_model.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  String? addItem({
    required Product product,
    required ProductUnit unit,
    required double quantity,
    required MarketType market,
  }) {
    final validationError = _validateQty(unit: unit, quantity: quantity);
    if (validationError != null) return validationError;

    final existingIndex = state.indexWhere(
      (item) => item.productId == product.id && item.unitCode == unit.code,
    );
    final existingQty = existingIndex >= 0
        ? state[existingIndex].quantity
        : 0.0;
    final mergedQty = existingQty + quantity;

    final baseRequested = mergedQty * unit.multiplierToBase;
    final reservedOtherUnits = state
        .where(
          (item) => item.productId == product.id && item.unitCode != unit.code,
        )
        .fold<double>(0, (total, item) => total + item.baseQuantity);
    if (reservedOtherUnits + baseRequested > product.availableStock) {
      return 'Insufficient stock. Available base stock: ${product.availableStock.toStringAsFixed(2)} ${product.baseUnit}.';
    }

    final pricing = _resolvePricing(product, unit);

    if (existingIndex >= 0) {
      final updated = state[existingIndex].copyWith(
        quantity: mergedQty,
        unitPrice: pricing.appliedUnitPrice,
        regularPriceQar: pricing.regularUnitPrice,
        offerPriceQar: pricing.offerUnitPrice,
        appliedPriceQar: pricing.appliedUnitPrice,
      );
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == existingIndex) updated else state[i],
      ];
      return null;
    }

    final line = CartItem(
      lineId:
          '${product.id}-${unit.code}-${DateTime.now().microsecondsSinceEpoch}',
      productId: product.id,
      productCode: product.code,
      productName: product.name,
      unitCode: unit.code,
      allowDecimal: unit.allowDecimal,
      multiplierToBase: unit.multiplierToBase,
      quantity: quantity,
      unitPrice: pricing.appliedUnitPrice,
      regularPriceQar: pricing.regularUnitPrice,
      offerPriceQar: pricing.offerUnitPrice,
      appliedPriceQar: pricing.appliedUnitPrice,
    );
    state = [...state, line];
    return null;
  }

  String? updateItem({
    required String lineId,
    required Product product,
    required ProductUnit unit,
    required double quantity,
    required MarketType market,
  }) {
    final validationError = _validateQty(unit: unit, quantity: quantity);
    if (validationError != null) return validationError;

    final current = state.firstWhere((e) => e.lineId == lineId);
    final requested = quantity * unit.multiplierToBase;
    final reservedOther = state
        .where((e) => e.productId == product.id && e.lineId != lineId)
        .fold<double>(0, (total, item) => total + item.baseQuantity);
    if (reservedOther + requested > product.availableStock) {
      return 'Insufficient stock for this update.';
    }

    final pricing = _resolvePricing(product, unit);

    final updated = current.copyWith(
      productCode: product.code,
      unitCode: unit.code,
      allowDecimal: unit.allowDecimal,
      multiplierToBase: unit.multiplierToBase,
      quantity: quantity,
      unitPrice: pricing.appliedUnitPrice,
      regularPriceQar: pricing.regularUnitPrice,
      offerPriceQar: pricing.offerUnitPrice,
      appliedPriceQar: pricing.appliedUnitPrice,
    );

    state = [
      for (final item in state)
        if (item.lineId == lineId) updated else item,
    ];
    _mergeSameProductAndUnit();
    return null;
  }

  void removeItem(String lineId) {
    state = state.where((e) => e.lineId != lineId).toList();
  }

  void clear() {
    state = const [];
  }

  String? _validateQty({required ProductUnit unit, required double quantity}) {
    if (!unit.allowDecimal && quantity % 1 != 0) {
      return 'Quantity for ${unit.code} must be an integer.';
    }
    if (quantity <= 0) {
      return 'Quantity must be greater than 0.';
    }
    return null;
  }

  _LinePricing _resolvePricing(Product product, ProductUnit unit) {
    final regularBase = product.priceQar > 0
        ? product.priceQar
        : (product.marketPrices[MarketType.hyper] ?? 0);
    final offerBase = product.offerPriceQar;
    final appliedBase = offerBase > 0 ? offerBase : regularBase;
    return _LinePricing(
      regularUnitPrice: regularBase * unit.multiplierToBase,
      offerUnitPrice: offerBase > 0 ? offerBase * unit.multiplierToBase : 0,
      appliedUnitPrice: appliedBase * unit.multiplierToBase,
    );
  }

  void _mergeSameProductAndUnit() {
    final grouped = <String, CartItem>{};
    for (final item in state) {
      final key = '${item.productId}__${item.unitCode}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = item;
      } else {
        grouped[key] = existing.copyWith(
          quantity: existing.quantity + item.quantity,
        );
      }
    }
    state = grouped.values.toList();
  }
}

class _LinePricing {
  const _LinePricing({
    required this.regularUnitPrice,
    required this.offerUnitPrice,
    required this.appliedUnitPrice,
  });

  final double regularUnitPrice;
  final double offerUnitPrice;
  final double appliedUnitPrice;
}

final orderHistoryProvider = StreamProvider<List<SalesOrder>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) {
    return Stream.value(const []);
  }
  final firestore = ref.read(firestoreProvider);

  return Stream.fromFuture(
    _resolveSalesmanIdentifiers(
      firestore: firestore,
      uid: authUser.uid,
      email: authUser.email,
    ),
  ).asyncExpand((ids) {
    if (ids.isEmpty) {
      return Stream.value(const <SalesOrder>[]);
    }
    return firestore
        .collection('catalog_orders')
        .where('salesmanId', whereIn: ids.take(10).toList())
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => _salesOrderFromDoc(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  });
});

final orderSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (total, item) => total + item.total);
});

final orderDiscountProvider = Provider<double>((ref) => 0);

final orderGrandTotalProvider = Provider<double>((ref) {
  return ref.watch(orderSubtotalProvider) - ref.watch(orderDiscountProvider);
});

final todaySummaryProvider = Provider<Map<String, num>>((ref) {
  final now = DateTime.now();
  final history = ref.watch(orderHistoryProvider).valueOrNull ?? const [];
  final todaysOrders = history.where((order) {
    return order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
  }).toList();
  final totalSales = todaysOrders.fold<double>(
    0.0,
    (total, o) => total + o.grandTotal,
  );
  return {
    'totalSales': totalSales,
    'orders': todaysOrders.length,
    'pending': 0,
  };
});

final todayDateLabelProvider = Provider<String>((ref) {
  return DateFormat('EEE, dd MMM yyyy').format(DateTime.now());
});

final productByIdProvider = Provider.family<Product?, String>((ref, id) {
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
  for (final product in products) {
    if (product.id == id) return product;
  }
  return null;
});

final orderSubmissionControllerProvider =
    StateNotifierProvider<
      OrderSubmissionController,
      AsyncValue<OrderSubmitResult?>
    >((ref) {
      return OrderSubmissionController(ref);
    });

class OrderSubmissionController
    extends StateNotifier<AsyncValue<OrderSubmitResult?>> {
  OrderSubmissionController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<OrderSubmitResult> submitOrder() async {
    if (state.isLoading) {
      return const OrderSubmitResult.failure(
        'Order submission already in progress.',
      );
    }
    state = const AsyncLoading();

    final customer = _ref.read(selectedCustomerProvider);
    final cart = _ref.read(cartProvider);
    if (customer == null) {
      const result = OrderSubmitResult.failure('Please select a customer.');
      state = const AsyncData(result);
      return result;
    }
    if (cart.isEmpty) {
      const result = OrderSubmitResult.failure('Add at least one product.');
      state = const AsyncData(result);
      return result;
    }

    for (final line in cart) {
      if (line.quantity <= 0) {
        const result = OrderSubmitResult.failure(
          'Each line quantity must be greater than 0.',
        );
        state = const AsyncData(result);
        return result;
      }
      if (!line.allowDecimal && line.quantity % 1 != 0) {
        final result = OrderSubmitResult.failure(
          'Quantity for ${line.productName} (${line.unitCode}) must be an integer.',
        );
        state = AsyncData(result);
        return result;
      }
    }

    try {
      final firestore = _ref.read(firestoreProvider);
      final latestProducts = <String, Product>{};
      for (final line in cart) {
        if (latestProducts.containsKey(line.productId)) continue;
        final doc = await firestore
            .collection('catalog_products')
            .doc(line.productId)
            .get();
        if (!doc.exists) {
          final result = OrderSubmitResult.failure(
            'Product ${line.productName} was removed.',
          );
          state = AsyncData(result);
          return result;
        }
        final map = doc.data() ?? <String, dynamic>{};
        if ((map['status'] as String?) != 'active') {
          final result = OrderSubmitResult.failure(
            'Product ${line.productName} is inactive.',
          );
          state = AsyncData(result);
          return result;
        }
        latestProducts[line.productId] = ProductModel.fromMap(doc.id, map);
      }

      final groupedBase = <String, double>{};
      for (final line in cart) {
        final product = latestProducts[line.productId]!;
        final hasUnit = product.units.any((u) => u.code == line.unitCode);
        if (!hasUnit) {
          final result = OrderSubmitResult.failure(
            'Unit ${line.unitCode} is not available for ${line.productName}.',
          );
          state = AsyncData(result);
          return result;
        }
        groupedBase[line.productId] =
            (groupedBase[line.productId] ?? 0) + line.baseQuantity;
      }

      for (final entry in groupedBase.entries) {
        final product = latestProducts[entry.key]!;
        if (entry.value > product.availableStock) {
          final result = OrderSubmitResult.failure(
            'Out of stock for ${product.name}. Available ${product.availableStock.toStringAsFixed(2)} ${product.baseUnit}.',
          );
          state = AsyncData(result);
          return result;
        }
      }

      final orderId = await _generateOrderId(firestore);
      final authUser = _ref.read(authStateProvider).valueOrNull;
      final amountQar = _ref.read(orderGrandTotalProvider);
      final items = cart.map((line) {
        return {
          'productCode': line.productCode,
          'productName': line.productName,
          'unit': line.unitCode,
          'qty': line.quantity,
          'conversionToBaseUnit': line.multiplierToBase,
          'qtyBase': line.baseQuantity,
          'unitPriceQar': line.regularPriceQar,
          'offerPriceQar': line.offerPriceQar > 0 ? line.offerPriceQar : null,
          'appliedPriceQar': line.appliedPriceQar,
          'lineTotalQar': line.total,
        };
      }).toList();

      await firestore.collection('catalog_orders').doc(orderId).set({
        'id': orderId,
        'customerId': customer.id,
        'customerName': customer.name,
        'salesmanId': authUser?.uid ?? 'unknown',
        'salesmanName': (authUser?.name ?? '').isNotEmpty
            ? authUser!.name
            : 'Salesman',
        'channel': 'Salesman App',
        'orderDate': FieldValue.serverTimestamp(),
        'itemsCount': cart.length,
        'amountQar': amountQar,
        'paymentStatus': 'pending',
        'orderStatus': 'processing',
        'items': items,
        'audit': {
          'createdAt': FieldValue.serverTimestamp(),
          'createdByUid': authUser?.uid ?? 'unknown',
        },
      });

      _ref.read(cartProvider.notifier).clear();

      final result = OrderSubmitResult.success(
        orderId: orderId,
        customerPhone: customer.phone,
        amountQar: amountQar,
      );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      final result = OrderSubmitResult.failure(e.toString());
      state = AsyncError(e, st);
      state = AsyncData(result);
      return result;
    }
  }

  Future<String> _generateOrderId(FirebaseFirestore firestore) async {
    final dateKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final counterRef = firestore
        .collection('_catalog_order_counters')
        .doc(dateKey);
    final seq = await firestore.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      final current = (snap.data()?['lastSeq'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      tx.set(counterRef, {
        'lastSeq': next,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return next;
    });
    return 'ORD-$dateKey-${seq.toString().padLeft(4, '0')}';
  }
}

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

SalesOrder _salesOrderFromDoc(String fallbackId, Map<String, dynamic> data) {
  var createdAt = DateTime.now();
  final dateRaw = data['orderDate'];
  if (dateRaw is Timestamp) {
    createdAt = dateRaw.toDate();
  }

  final itemsRaw = (data['items'] as List?) ?? const [];
  final items = itemsRaw.asMap().entries.map((entry) {
    final index = entry.key;
    final itemMap = entry.value is Map<String, dynamic>
        ? entry.value as Map<String, dynamic>
        : <String, dynamic>{};
    final qty = (itemMap['qty'] as num?)?.toDouble() ?? 0;
    final applied = (itemMap['appliedPriceQar'] as num?)?.toDouble();
    final unit = (itemMap['unitPriceQar'] as num?)?.toDouble();
    final lineTotal = (itemMap['lineTotalQar'] as num?)?.toDouble() ?? 0;
    final resolvedUnit = applied ?? unit ?? (qty == 0 ? 0 : lineTotal / qty);
    final productCode = (itemMap['productCode'] as String?) ?? '';
    final productId = (itemMap['productId'] as String?) ?? productCode;

    return CartItem(
      lineId: '$fallbackId-$index',
      productId: productId,
      productCode: productCode,
      productName: (itemMap['productName'] as String?) ?? 'Product',
      unitCode: (itemMap['unit'] as String?) ?? '',
      allowDecimal: true,
      multiplierToBase:
          (itemMap['conversionToBaseUnit'] as num?)?.toDouble() ?? 1,
      quantity: qty,
      unitPrice: resolvedUnit,
      regularPriceQar:
          (itemMap['unitPriceQar'] as num?)?.toDouble() ?? resolvedUnit,
      offerPriceQar: (itemMap['offerPriceQar'] as num?)?.toDouble() ?? 0,
      appliedPriceQar: applied ?? resolvedUnit,
    );
  }).toList();

  final subtotal = items.fold<double>(0, (total, item) => total + item.total);
  final grandTotal = (data['amountQar'] as num?)?.toDouble() ?? subtotal;
  final customer = Customer(
    id: (data['customerId'] as String?) ?? '',
    name: (data['customerName'] as String?) ?? 'Customer',
    phone: (data['customerPhone'] as String?) ?? '',
    marketType: MarketType.local,
    outstandingBalance: 0,
  );

  return SalesOrder(
    id: (data['id'] as String?) ?? fallbackId,
    createdAt: createdAt,
    customer: customer,
    items: items,
    subtotal: subtotal,
    discount: (subtotal - grandTotal).clamp(0, subtotal).toDouble(),
    grandTotal: grandTotal,
  );
}

class OrderSubmitResult {
  const OrderSubmitResult._({
    required this.ok,
    this.error,
    this.orderId,
    this.customerPhone,
    this.amountQar,
  });

  const OrderSubmitResult.success({
    required String orderId,
    required String customerPhone,
    required double amountQar,
  }) : this._(
         ok: true,
         orderId: orderId,
         customerPhone: customerPhone,
         amountQar: amountQar,
       );

  const OrderSubmitResult.failure(String message)
    : this._(ok: false, error: message);

  final bool ok;
  final String? error;
  final String? orderId;
  final String? customerPhone;
  final double? amountQar;
}

final confirmOrderProvider = Provider<Future<String?> Function()>((ref) {
  return () async {
    final result = await ref
        .read(orderSubmissionControllerProvider.notifier)
        .submitOrder();
    return result.ok ? null : result.error;
  };
});
