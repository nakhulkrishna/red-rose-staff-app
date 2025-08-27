import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart' show Iconsax;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/products/provider/products_management.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Orders"),),
      body:     Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<ProductProvider>(
                builder: (context, value, child) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: value.orders.length,
                    itemBuilder: (context, index) {
                      final orders = value.orders[index];
                      String formattedDate = orders.timestamp != null
                          ? DateFormat('d MMM yyyy').format(orders.timestamp!)
                          : '';
                      return buildTransaction(
                        context,
                        orders.productName,
                        formattedDate,
                        orders.price.toString(),
                      );
                    },
                  );
                },
              ),
      ),
            
    );
  }
    Widget buildTransaction(
    BuildContext context,
    String name,
    String date,
    String txnId,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.primaryColor,
            child: const Icon(Iconsax.box, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Ordered",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(txnId, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

}