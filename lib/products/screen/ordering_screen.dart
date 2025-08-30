import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/order_products/provider/order.dart';
import 'package:staff_app/products/provider/products_management.dart';

class OrderScreen extends StatelessWidget {
  final List<Product> products;
  final List<SelectedOrder> order;
  final String buyername;

  const OrderScreen({
    super.key,
    required this.products,
    required this.order,
    required this.buyername,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ProductProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false); // false = order not placed
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Selected Products")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...products.map((product) {
                  final productId = product.id;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: product.images.isNotEmpty
                            ? Image.memory(
                                base64Decode(product.images.first),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image, size: 50),
                        title: Text(product.name),
                        subtitle: Text(
                          "Price: QR ${product.offerPrice ?? product.price} | Stock: ${product.stock}",
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Unit type selector
                      Row(
                        children: [
                          const Text("Unit: "),
                          DropdownButton<String>(
                            value: provider.unitType(productId),
                            items: const [
                              DropdownMenuItem(value: 'Kg', child: Text("Kg")),
                              DropdownMenuItem(
                                value: 'Cartoon',
                                child: Text("Cartoon"),
                              ),
                            ],
                            onChanged: (value) {
                              provider.setUnitType(productId, value!);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Conditional input
                      if (provider.unitType(productId) == 'Kg')
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Enter weight in Kg",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: provider.weightController(productId),
                          onChanged: (val) {
                            provider.setWeight(productId, val);
                          },
                        )
                      else
                        Row(
                          children: [
                            const Text("Quantity: "),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (provider.quantity(productId) > 1) {
                                  provider.setQuantity(
                                    productId,
                                    provider.quantity(productId) - 1,
                                  );
                                }
                              },
                            ),
                            Text(provider.quantity(productId).toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                provider.setQuantity(
                                  productId,
                                  provider.quantity(productId) + 1,
                                );
                              },
                            ),
                          ],
                        ),
                      const Divider(),
                    ],
                  );
                }).toList(),

                const SizedBox(height: 20),

                // Place All Orders Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text(
                      "Place All Orders",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirm Order"),
                          content: const Text(
                            "Are you sure you want to place all orders?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text("Confirm"),
                            ),
                          ],
                        ),
                      );

                      // If user confirms
                      if (confirm == true) {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        final userid = prefs.getString('user_id') ?? "";

                        // Collect selected orders
                        List<Map<String, dynamic>> selectedOrders = [];

                        for (var product in products) {
                          final pid = product.id;
                          if (product.stock > 0) {
                            final unit = provider.unitType(pid);
                            final qty = unit == 'Cartoon'
                                ? provider.quantity(pid)
                                : 1;
                            final weight = unit == 'Kg'
                                ? provider.weight(pid)
                                : null;

                            selectedOrders.add({
                              "product": product,
                              "qty": qty,
                              "weight": weight,
                            });
                          }
                        }

                        if (selectedOrders.isNotEmpty) {
                          await provider.sendOrderWhatsAppMultiple(
                            selectedOrders,
                            context,
                            buyername,
                            salesManId: userid,
                          );
                        }

                        provider.clearSelections();
                        Navigator.pop(context);
                      }
                    },

                    // onPressed: () async {
                    //   SharedPreferences prefs =
                    //       await SharedPreferences.getInstance();
                    //   final userid = prefs.getString('user_id') ?? "";

                    //   // Collect selected orders
                    //   List<Map<String, dynamic>> selectedOrders = [];

                    //   for (var product in products) {
                    //     final pid = product.id;
                    //     if (product.stock > 0) {
                    //       final unit = provider.unitType(pid);
                    //       final qty = unit == 'Cartoon'
                    //           ? provider.quantity(pid)
                    //           : 1;
                    //       final weight = unit == 'Kg'
                    //           ? provider.weight(pid)
                    //           : null;

                    //       selectedOrders.add({
                    //         "product": product,
                    //         "qty": qty,
                    //         "weight": weight,
                    //       });
                    //     }
                    //   }

                    //   if (selectedOrders.isNotEmpty) {
                    //     await provider.sendOrderWhatsAppMultiple(
                    //       selectedOrders,
                    //       context,
                    //       buyername,
                    //       salesManId: userid,
                    //     );
                    //   }

                    //   provider.clearSelections();
                    //   Navigator.pop(context);
                    // },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
