import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/customers/presentation/providers/customers_provider.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final customers = ref.watch(customersProvider);

    final filtered = customers.where((customer) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          customer.name.toLowerCase().contains(q) ||
          customer.phone.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Customers',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or phone',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Failed to load customers: $error')),
                data: (_) => filtered.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${customer.phone}\n${customer.marketType.label} • Outstanding QAR ${customer.outstandingBalance.toStringAsFixed(2)}',
                                ),
                                isThreeLine: true,
                                trailing: widget.selectionMode
                                    ? const Icon(Icons.check_circle_outline)
                                    : const Icon(Icons.chevron_right),
                                onTap: () {
                                  ref
                                          .read(
                                            selectedCustomerProvider.notifier,
                                          )
                                          .state =
                                      customer;
                                  Navigator.of(context).pop(customer);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
