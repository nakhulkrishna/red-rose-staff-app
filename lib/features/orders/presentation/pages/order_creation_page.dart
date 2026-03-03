import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/customers/domain/entities/customer.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/orders/presentation/pages/order_summary_page.dart';
import 'package:staff_app/features/orders/presentation/providers/order_controller.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:staff_app/shared/widgets/price_mode_banner.dart';

class OrderCreationPage extends ConsumerStatefulWidget {
  const OrderCreationPage({super.key});

  @override
  ConsumerState<OrderCreationPage> createState() => _OrderCreationPageState();
}

enum _FilterType { all, inStock, lowStock, category }

class _OrderCreationPageState extends ConsumerState<OrderCreationPage> {
  String _query = '';
  _FilterType _filterType = _FilterType.all;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentCustomerIds = <String>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(selectedCustomerProvider);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(orderGrandTotalProvider);
    final productsAsync = ref.watch(productsProvider);
    final allCustomers = ref.watch(customersProvider);
    final marketContextAsync = ref.watch(salesmanMarketContextProvider);
    final marketType =
        marketContextAsync.valueOrNull?.marketType ?? MarketType.local;
    final priceModeLabel =
        marketContextAsync.valueOrNull?.priceModeLabel ?? 'Local Market';
    final recentCustomers = _recentCustomerIds
        .map((id) {
          for (final customer in allCustomers) {
            if (customer.id == id) return customer;
          }
          return null;
        })
        .whereType<Customer>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: PriceModeBanner(label: priceModeLabel),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: _CustomerChip(
              customer: customer,
              onChange: _selectCustomer,
              onClear: customer == null
                  ? null
                  : () => ref.read(selectedCustomerProvider.notifier).state =
                        null,
            ),
          ),
          if (recentCustomers.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: recentCustomers.map((recent) {
                  final isSelected = customer?.id == recent.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.history_toggle_off_outlined,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF6B7280),
                      ),
                      label: Text(recent.name),
                      onPressed: () {
                        ref.read(selectedCustomerProvider.notifier).state =
                            recent;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          productsAsync.when(
            data: (products) => _FilterChips(
              products: products,
              selected: _filterType,
              selectedCategory: _selectedCategory,
              onSelectBasic: (type) {
                setState(() {
                  _filterType = type;
                  if (type != _FilterType.category) _selectedCategory = null;
                });
              },
              onSelectCategory: (category) {
                setState(() {
                  _filterType = _FilterType.category;
                  _selectedCategory = category;
                });
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = _applyFilters(products);
                final inStockCount = filtered
                    .where((p) => p.availableStock > 0)
                    .length;
                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
                      child: Row(
                        children: [
                          _StatPill(
                            icon: Icons.view_list_outlined,
                            label: '${filtered.length} products',
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            icon: Icons.inventory_2_outlined,
                            label: '$inStockCount in stock',
                          ),
                          const Spacer(),
                          _StatPill(
                            icon: Icons.shopping_cart_outlined,
                            label: '${cart.length} in cart',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                        itemCount: filtered.length,
                        cacheExtent: 720,
                        addAutomaticKeepAlives: false,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final addedCount = cart
                              .where((line) => line.productId == product.id)
                              .length;
                          return _ProductOrderCard(
                            product: product,
                            addedCount: addedCount,
                            customer: customer,
                            onAdd: () =>
                                _addDefault(product, customer, marketType),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load products:\n$error'),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cart.length} items',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'QAR ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: cart.isEmpty ? null : _openCartEditor,
              child: const Text('Edit Cart'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      if (customer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Select customer first.'),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrderSummaryPage(),
                        ),
                      );
                    },
              child: const Text('Review'),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _applyFilters(List<Product> products) {
    final q = _query.toLowerCase();
    return products.where((product) {
      final matchesSearch =
          q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          product.code.toLowerCase().contains(q);
      if (!matchesSearch) return false;

      switch (_filterType) {
        case _FilterType.all:
          return true;
        case _FilterType.inStock:
          return product.availableStock > 0;
        case _FilterType.lowStock:
          return product.availableStock > 0 && product.availableStock <= 10;
        case _FilterType.category:
          return _selectedCategory == null ||
              product.category == _selectedCategory;
      }
    }).toList();
  }

  Future<void> _selectCustomer() async {
    final selected = await _openCustomerPicker();
    if (selected != null) {
      ref.read(selectedCustomerProvider.notifier).state = selected;
      _rememberRecentCustomer(selected);
    }
  }

  Future<Customer?> _openCustomerPicker() async {
    var query = '';
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final customersAsync = ref.watch(customersStreamProvider);
                final currentSelected = ref.watch(selectedCustomerProvider);
                return FractionallySizedBox(
                  heightFactor: 0.86,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (value) => setModalState(
                              () => query = value.trim().toLowerCase(),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or phone',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: customersAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, _) =>
                                  Center(child: Text('Failed to load: $error')),
                              data: (customers) {
                                final filtered = customers.where((c) {
                                  if (query.isEmpty) return true;
                                  return c.name.toLowerCase().contains(query) ||
                                      c.phone.toLowerCase().contains(query);
                                }).toList();
                                if (filtered.isEmpty) {
                                  return const Center(
                                    child: Text('No customers found'),
                                  );
                                }
                                return ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final customer = filtered[index];
                                    final isSelected =
                                        currentSelected?.id == customer.id;
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0F766E)
                                              : const Color(0xFFE5E7EB),
                                          width: isSelected ? 1.6 : 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        onTap: () =>
                                            Navigator.of(context).pop(customer),
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFF3F4F6),
                                          child: Icon(
                                            Icons.person_outline,
                                            color: isSelected
                                                ? const Color(0xFF0F766E)
                                                : null,
                                          ),
                                        ),
                                        title: Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${customer.phone}\nOutstanding QAR ${customer.outstandingBalance.toStringAsFixed(2)}',
                                        ),
                                        isThreeLine: true,
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF0F766E),
                                              )
                                            : const Icon(Icons.chevron_right),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _rememberRecentCustomer(Customer customer) {
    setState(() {
      _recentCustomerIds.remove(customer.id);
      _recentCustomerIds.insert(0, customer.id);
      if (_recentCustomerIds.length > 5) {
        _recentCustomerIds.removeRange(5, _recentCustomerIds.length);
      }
    });
  }

  void _addDefault(Product product, Customer? customer, MarketType marketType) {
    if (customer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select customer first.')));
      return;
    }
    final unit = product.units.first;
    final error = ref
        .read(cartProvider.notifier)
        .addItem(product: product, unit: unit, quantity: 1, market: marketType);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _openCartEditor() async {
    final customer = ref.read(selectedCustomerProvider);
    if (customer == null) return;
    final marketType = ref.read(salesmanMarketTypeProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cart = ref.read(cartProvider);
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            final line = cart[index];
                            final product = ref.read(
                              productByIdProvider(line.productId),
                            );
                            if (product == null) return const SizedBox.shrink();
                            final unit = product.units.firstWhere(
                              (u) => u.code == line.unitCode,
                              orElse: () => product.units.first,
                            );
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final compact =
                                            constraints.maxWidth < 380;
                                        return Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: compact
                                                  ? constraints.maxWidth * 0.45
                                                  : 110,
                                              child:
                                                  DropdownButtonFormField<
                                                    ProductUnit
                                                  >(
                                                    initialValue: unit,
                                                    items: product.units
                                                        .map(
                                                          (u) =>
                                                              DropdownMenuItem(
                                                                value: u,
                                                                child: Text(
                                                                  u.code,
                                                                ),
                                                              ),
                                                        )
                                                        .toList(),
                                                    onChanged: (value) {
                                                      if (value == null) return;
                                                      final latestCart = ref
                                                          .read(cartProvider);
                                                      final latestIndex =
                                                          latestCart.indexWhere(
                                                            (e) =>
                                                                e.lineId ==
                                                                line.lineId,
                                                          );
                                                      if (latestIndex < 0) {
                                                        setModalState(() {});
                                                        setState(() {});
                                                        return;
                                                      }
                                                      final latestLine =
                                                          latestCart[latestIndex];
                                                      final error = ref
                                                          .read(
                                                            cartProvider
                                                                .notifier,
                                                          )
                                                          .updateItem(
                                                            lineId: line.lineId,
                                                            product: product,
                                                            unit: value,
                                                            quantity: latestLine
                                                                .quantity,
                                                            market: marketType,
                                                          );
                                                      if (error != null) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              error,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                      setModalState(() {});
                                                      setState(() {});
                                                    },
                                                  ),
                                            ),
                                            _QtyStepper(
                                              qty: line.quantity,
                                              onDecrement: () {
                                                final latestCart = ref.read(
                                                  cartProvider,
                                                );
                                                final latestIndex = latestCart
                                                    .indexWhere(
                                                      (e) =>
                                                          e.lineId ==
                                                          line.lineId,
                                                    );
                                                if (latestIndex < 0) {
                                                  setModalState(() {});
                                                  setState(() {});
                                                  return;
                                                }
                                                final latestLine =
                                                    latestCart[latestIndex];
                                                final latestUnit = product.units
                                                    .firstWhere(
                                                      (u) =>
                                                          u.code ==
                                                          latestLine.unitCode,
                                                      orElse: () =>
                                                          product.units.first,
                                                    );
                                                final next =
                                                    latestLine.quantity > 1
                                                    ? latestLine.quantity - 1
                                                    : 1.0;
                                                final error = ref
                                                    .read(cartProvider.notifier)
                                                    .updateItem(
                                                      lineId: line.lineId,
                                                      product: product,
                                                      unit: latestUnit,
                                                      quantity: next,
                                                      market: marketType,
                                                    );
                                                if (error != null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(error),
                                                    ),
                                                  );
                                                }
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                              onIncrement: () {
                                                final latestCart = ref.read(
                                                  cartProvider,
                                                );
                                                final latestIndex = latestCart
                                                    .indexWhere(
                                                      (e) =>
                                                          e.lineId ==
                                                          line.lineId,
                                                    );
                                                if (latestIndex < 0) {
                                                  setModalState(() {});
                                                  setState(() {});
                                                  return;
                                                }
                                                final latestLine =
                                                    latestCart[latestIndex];
                                                final latestUnit = product.units
                                                    .firstWhere(
                                                      (u) =>
                                                          u.code ==
                                                          latestLine.unitCode,
                                                      orElse: () =>
                                                          product.units.first,
                                                    );
                                                final error = ref
                                                    .read(cartProvider.notifier)
                                                    .updateItem(
                                                      lineId: line.lineId,
                                                      product: product,
                                                      unit: latestUnit,
                                                      quantity:
                                                          latestLine.quantity +
                                                          1,
                                                      market: marketType,
                                                    );
                                                if (error != null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(error),
                                                    ),
                                                  );
                                                }
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                            ),
                                            SizedBox(
                                              width: compact
                                                  ? constraints.maxWidth * 0.42
                                                  : 130,
                                              child: Text(
                                                'QAR ${line.total.toStringAsFixed(2)}',
                                                textAlign: compact
                                                    ? TextAlign.left
                                                    : TextAlign.right,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                ref
                                                    .read(cartProvider.notifier)
                                                    .removeItem(line.lineId);
                                                setModalState(() {});
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomerChip extends StatelessWidget {
  const _CustomerChip({
    required this.customer,
    required this.onChange,
    this.onClear,
  });

  final Customer? customer;
  final VoidCallback onChange;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              customer == null ? Icons.person_search : Icons.person_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer == null ? 'Customer not selected' : customer!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  customer == null
                      ? 'Select a customer before reviewing order'
                      : '${customer!.phone} • Outstanding QAR ${customer!.outstandingBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(customer == null ? 'Select' : 'Change'),
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 18),
              tooltip: 'Clear customer',
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.products,
    required this.selected,
    required this.selectedCategory,
    required this.onSelectBasic,
    required this.onSelectCategory,
  });

  final List<Product> products;
  final _FilterType selected;
  final String? selectedCategory;
  final ValueChanged<_FilterType> onSelectBasic;
  final ValueChanged<String> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final categories = products.map((e) => e.category).toSet().toList()..sort();
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(
            label: 'All',
            selected: selected == _FilterType.all,
            onTap: () => onSelectBasic(_FilterType.all),
          ),
          _chip(
            label: 'In Stock',
            selected: selected == _FilterType.inStock,
            onTap: () => onSelectBasic(_FilterType.inStock),
          ),
          _chip(
            label: 'Low Stock',
            selected: selected == _FilterType.lowStock,
            onTap: () => onSelectBasic(_FilterType.lowStock),
          ),
          ...categories.map(
            (category) => _chip(
              label: category,
              selected:
                  selected == _FilterType.category &&
                  selectedCategory == category,
              onTap: () => onSelectCategory(category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ProductOrderCard extends StatelessWidget {
  const _ProductOrderCard({
    required this.product,
    required this.addedCount,
    required this.customer,
    required this.onAdd,
  });

  final Product product;
  final int addedCount;
  final Customer? customer;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      name: 'QAR',
      symbol: 'QAR ',
      decimalDigits: 2,
    );
    final isLow = product.availableStock > 0 && product.availableStock <= 10;
    final hasOffer =
        product.offerPriceQar > 0 && product.offerPriceQar < product.priceQar;
    final imageUrls = product.imageUrls.isEmpty
        ? (product.imageUrl.isEmpty ? <String>[] : [product.imageUrl])
        : product.imageUrls;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: imageUrls.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _OrderProductImageViewerPage(
                                productName: product.name,
                                imageUrls: imageUrls,
                              ),
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _CardImage(url: product.imageUrl),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        product.code,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _tag(product.category),
                          _tag('Base: ${product.baseUnit}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isLow
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isLow
                                  ? 'Low Stock: ${product.availableStock.toStringAsFixed(0)}'
                                  : 'In Stock: ${product.availableStock.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isLow
                                    ? const Color(0xFF9A3412)
                                    : const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            money.format(product.priceQar),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: hasOffer
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: hasOffer
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF111827),
                            ),
                          ),
                          if (hasOffer) ...[
                            const SizedBox(width: 8),
                            Text(
                              money.format(product.offerPriceQar),
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: customer == null ? null : onAdd,
                  child: const Text('Add'),
                ),
              ],
            ),
            if (addedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'In cart: $addedCount',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF374151)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  final double qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final isInt = qty % 1 == 0;
    final label = isInt ? qty.toInt().toString() : qty.toStringAsFixed(2);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 18),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 18),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 70,
        height: 70,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.image_outlined),
      );
    }
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final targetPixels = (70 * pixelRatio).round().clamp(1, 1024);
    return Image.network(
      url,
      width: 70,
      height: 70,
      cacheWidth: targetPixels,
      cacheHeight: targetPixels,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) => Container(
        width: 70,
        height: 70,
        color: const Color(0xFFF3F4F6),
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _OrderProductImageViewerPage extends StatefulWidget {
  const _OrderProductImageViewerPage({
    required this.productName,
    required this.imageUrls,
  });

  final String productName;
  final List<String> imageUrls;

  @override
  State<_OrderProductImageViewerPage> createState() =>
      _OrderProductImageViewerPageState();
}

class _OrderProductImageViewerPageState
    extends State<_OrderProductImageViewerPage> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.productName),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final mediaSize = MediaQuery.sizeOf(context);
                final pixelRatio = MediaQuery.of(context).devicePixelRatio;
                final cacheWidth = (mediaSize.width * pixelRatio * 2)
                    .round()
                    .clamp(1, 2500);
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Text(
                '${_index + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
