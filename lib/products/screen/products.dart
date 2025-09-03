import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/authentication/provider/authentication_provider.dart';
import 'package:staff_app/order_products/provider/customer.dart';
import 'package:staff_app/orders/screen/orders_screen.dart';
import 'package:staff_app/products/provider/products_management.dart';
import 'package:staff_app/products/screen/products_management.dart';
import 'package:staff_app/products/screen/products_screen.dart';
import 'package:staff_app/settings/screens/settings.dart';
import 'package:staff_app/order_products/provider/provider.dart';
import 'package:staff_app/order_products/screen/staff_management.dart';
import 'package:staff_app/theme/themeprovider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              icon: Icon(
                themeProvider.isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
              ),
            );
          },
        ),

        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Welcome back!", style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final name = userProvider.currentUser?.name ?? "Guest";
                return Text(
                  name.toUpperCase(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: Icon(Iconsax.setting, color: theme.iconTheme.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.wallet_3, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Total Sale Value",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      // Text(
                      //   "See details",
                      //   style: theme.textTheme.bodyMedium?.copyWith(
                      //     color: theme.colorScheme.primary,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<ProductProvider>(
                    builder: (context, value, child) {
                      return Text(
                        "\u20B9${value.totalOrderValue.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats
            Consumer2<ProductProvider, Costomer>(
              builder: (context, value, staff, child) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 15,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Navigate to ProductsScreen
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductsScreen(
                              isThisFormCustomers: false,
                              buyername: "",
                            ),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.box,
                        "Products",
                        "${value.products.length}",
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrdersScreen(),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.shopping_cart,
                        "Orders",
                        "${value.orders.length} ",
                      ),
                    ),
                    buildStatCard(
                      context,
                      Iconsax.category,
                      "Categories",
                      "${value.categories.length}",
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddStaffScreen(),
                          ),
                        );
                      },
                      child: buildStatCard(
                        context,
                        Iconsax.people,
                        "Customer & Order",
                        "${staff.staffList.length}",
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              "Recent Orders",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<ProductProvider>(
              builder: (context, value, child) {
                if (value.orders.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Image.asset(
                          'asstes/Image.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No orders yet",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: value.orders.length > 8
                        ? 8
                        : value.orders.length,
                    itemBuilder: (context, index) {
                      final orders = value.orders[index];
                      String formattedDate = orders.timestamp != null
                          ? DateFormat('d MMM yyyy').format(orders.timestamp!)
                          : '';
                      return buildTransaction(
                        context,
                        orders.productName,
                        formattedDate,
                        orders.total.toString(),
                      );
                    },
                  );
                }
              },
            ),],
        ),
      ),
    );
  }

  Widget buildStatCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.iconTheme.color, size: 30),
          const SizedBox(height: 12),
          AutoSizeText(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            minFontSize: 20, // shrink if too long
            maxFontSize: 50, // normal max size
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall!.copyWith(fontSize: 15)),
        ],
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


