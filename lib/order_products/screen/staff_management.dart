import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/order_products/provider/customer.dart';
import 'package:staff_app/order_products/provider/provider.dart';
import 'package:staff_app/order_products/screen/add_customers.dart';
import 'package:staff_app/products/screen/products_screen.dart';

class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<Costomer>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => provider.setSearchQuery(value),
              decoration: InputDecoration(
                hintText: "Search Customers...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCustomers()),
              );
            },
            icon: Icon(Iconsax.user_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<Costomer>(
          builder: (context, value, child) {
            final list = value.filteredStaff; // use filtered staff
            if (list.isEmpty)
              return const Center(child: Text("No customers found"));

            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final customer = list[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsScreen(isThisFormCustomers: true,buyername:  customer['username'] ?? '',),));
                  },
                  child: buildTransaction(
                    context,
                    customer['username'] ?? '',
                    customer['phoneNumber'] ?? '',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildTransaction(BuildContext context, String name, String date) {
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
            child: const Icon(Iconsax.user4, color: Colors.white),
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
        ],
      ),
    );
  }
}
