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
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true, // ✅ Make dropdown full width
                                value: provider.unitType(productId),
                                underline:
                                    const SizedBox(), // Remove default underline
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Kg',
                                    child: Text("Kg"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Piece',
                                    child: Text("Piece"),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cartoon',
                                    child: Text("Cartoon"),
                                  ),
                                ],
                                onChanged: (value) {
                                  provider.setUnitType(productId, value!);
                                  provider.calculateTotal(
                                    productId,product
                                  ); // ✅ Recalculate
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (provider.unitType(productId) == 'Kg') ...[
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Enter weight in Kg",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          controller: provider.kgController(productId),
                          onChanged: (val) =>
                              provider.calculateTotal(productId, product),
                        ),
                        
                      ] else if (provider.unitType(productId) == 'Piece') ...[
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Enter number of pieces",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: provider.pieceController(productId),
                          onChanged: (val) =>
                               provider.calculateTotal(productId, product),
                        ),
                        
                      ] else if (provider.unitType(productId) == 'Cartoon') ...[
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Enter number of cartons",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: provider.ctrController(productId),
                          onChanged: (val) =>
                                provider.calculateTotal(productId, product),
                        ),
                        
                      ],
                      // After Dropdown and quantity/weight input
                      Text(
                        "Total: QR ${provider.productTotal(product.id).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),
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
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirm Order"),
      content: const Text("Are you sure you want to place all orders?"),
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

  if (confirm == true) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userid = prefs.getString('user_id') ?? "";

    List<Map<String, dynamic>> selectedOrders = [];

    // ✅ Populate orders
    for (var product in products) {
      final pid = product.id;
      final unit = provider.unitType(pid);
      double qty = 0;
      double? weight;

      if (unit == 'Kg') {
        weight = double.tryParse(provider.kgController(pid)?.text ?? "0") ?? 0;
        qty = weight; // if you need quantity as weight
      } else if (unit == 'Piece') {
        qty = double.tryParse(provider.pieceController(pid)?.text ?? "0") ?? 0;
      } else if (unit == 'Cartoon') {
        qty = double.tryParse(provider.ctrController(pid)?.text ?? "0") ?? 0;
      }

      if (qty > 0) {
        selectedOrders.add({
          "product": product,
          "qty": qty,
          "weight": weight,
        });
      }
    }

    // ✅ Send order only if there are products
    if (selectedOrders.isNotEmpty) {
      await provider.sendOrderWhatsAppMultiple(
        selectedOrders,
        context,
        buyername,
        salesManId: userid,
      );

      provider.clearSelections();
      Navigator.pop(context); // Go back to products screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No products selected")),
      );
    }
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
