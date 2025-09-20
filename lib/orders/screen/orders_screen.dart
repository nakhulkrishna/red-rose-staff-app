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
      appBar: AppBar(title: Text("Orders")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<ProductProvider>(
          builder: (context, value, child) {
            if (value.orders.isEmpty) {
              return SizedBox(
                height: MediaQuery.of(context).size.height, // fill screen
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // center content
                    children: [
                      Image.asset(
                        'asstes/Image.png', // fix typo: 'asstes' → 'assets'
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No orders yet",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: value.orders.length > 8 ? 8 : value.orders.length,
                itemBuilder: (context, index) {
                  final orders = value.orders[index];
                  String formattedDate = orders.timestamp != null
                      ? DateFormat('d MMM yyyy').format(orders.timestamp!)
                      : '';

                  return Dismissible(
                    key: Key(
                      orders.orderId,
                    ), // make sure your Order model has an "id"
                    direction:
                        DismissDirection.endToStart, // swipe left to delete
                    background: Container(
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Order"),
                          content: const Text(
                            "Are you sure you want to delete this order?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      Provider.of<ProductProvider>(
                        context,
                        listen: false,
                      ).deleteOrder(orders.orderId);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Order deleted")),
                      );
                    },
                    child: buildTransaction(
                      context,
                      orders.productName,
                      formattedDate,
                      orders.total.toString(),
                    ),
                  );
                },
              );
            }
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
