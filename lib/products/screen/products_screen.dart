import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/order_products/provider/order.dart';
import 'package:staff_app/products/provider/products_management.dart';
import 'package:staff_app/products/screen/ordering_screen.dart';
import 'package:staff_app/theme/colors.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({
    super.key,
    required this.isThisFormCustomers,
    required this.buyername,
  });
  final bool isThisFormCustomers;
  final String buyername;
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Provider.of<ProductProvider>(context, listen: false).clearSelections();
        return true; // allow back navigation
      },
      child: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final products = provider.filteredProducts;
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text("Products"),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: (value) => provider.setSearchQuery(value),
                    decoration: InputDecoration(
                      hintText: "Search products...",
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
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // 🔹 Category chips
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final theme = Theme.of(context);

                        if (index == 0) {
                          final isSelected = provider.selectedCategory == null;
                          return ChoiceChip(
                            label: const Text("All"),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: theme.chipTheme.backgroundColor,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                            onSelected: (_) => provider.setCategory(null),
                          );
                        }

                        final cat = provider.categories[index - 1];
                        final isSelected =
                            provider.selectedCategory == cat.name;

                        return ChoiceChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.chipTheme.backgroundColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.textTheme.bodyMedium?.color,
                          ),
                          onSelected: (_) => provider.setCategory(cat.name),
                        );
                      },
                    ),
                  ),

                  // 🔹 Products grid
                  Expanded(
                    child: products.isEmpty
                        ? SizedBox(
                            height:
                                MediaQuery.of(context).size.height -
                                kToolbarHeight, // screen height minus AppBar
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'asstes/Image-3.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No products found",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,

                            itemCount: provider.filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return ProductListTile(
                                from: isThisFormCustomers,
                                productProvider: provider,
                                product: product,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.selectedProducts.isEmpty) return SizedBox.shrink();

                return FloatingActionButton.extended(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () async {
                    // SharedPreferences prefs =
                    //     await SharedPreferences.getInstance();
                    // final userid = prefs.getString('user_id');

                    // for (var product in provider.selectedProducts) {
                    //   // For now assume quantity=1, buyer/color/shop can be asked later
                    //   await provider.sendOrderWhatsApp(
                    //     product,
                    //     1, // quantity
                    //     context,
                    //     buyername,
                    //     salesManId: userid ?? "",
                    //   );
                    // }

                    // provider.clearSelections(); // reset after ordering

                    List<SelectedOrder> orders = provider.selectedProducts.map((
                      element,
                    ) {
                      return SelectedOrder(
                        product: element,
                        quantity: 0, // or your actual quantity
                        buyer: buyername,
                      );
                    }).toList();

                    final orderPlaced = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderScreen(
                          products: provider.selectedProducts,
                          order: orders,
                          buyername: buyername,
                        ),
                      ),
                    );

                    // Clear selections only if order was NOT placed
                    if (orderPlaced != true) {
                      provider.clearSelections();
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(
                    "Order ${provider.selectedProducts.length} Items",
                    style: TextStyle(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProductListTile extends StatelessWidget {
  final bool from;
  final ProductProvider productProvider;
  final Product product;

  const ProductListTile({
    super.key,
    required this.product,
    required this.productProvider,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Product Image
            SizedBox(
              height: 100,width: 100,
              child: GestureDetector(
                onTap: () {
                  if (product.images != null &&
                      product.images.isNotEmpty &&
                      product.images.first.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ImagePreviewPage(images: product.images),
                      ),
                    );
                  }
                },
                child:
                    (product.images == null ||
                        product.images.isEmpty ||
                        product.images.first.isEmpty)
                    ? const Icon(Iconsax.image)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(product.images.first),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // 🔹 Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Row(
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1, // only one line
                          minFontSize: 10, // don’t shrink below this
                          overflow: TextOverflow.ellipsis, // optional "..."
                        ),
                      ),
                      from == true
                          ? Checkbox(
                              value: productProvider.isProductSelected(
                                product.id,
                              ),
                              onChanged: (value) {
                                productProvider.toggleProductSelection(
                                  product.id,
                                );
                              },
                            )
                          : SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category
                  Row(
                    children: [
                      Text(
                        "Category :",
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        " ${product.categoryId}",
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price + Offer Price
                  product.offerPrice == null
                      ? Row(
                          children: [
                            Text(
                              "Price    :",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Spacer(),
                            Text(
                              " QR ${product.price}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              "QR ${product.price}",
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "QR ${product.offerPrice}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Hyper  :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Spacer(),
                      Text(
                        " QR ${product.hyperMarket}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Stock
                  Row(
                    children: [
                      Text(
                        product.stock == 0 ? "Out of Stock" : "Stock   :",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: product.stock == 0
                              ? Colors.redAccent
                              : theme.colorScheme.primary,
                        ),
                      ),
                      Spacer(),
                      Text(
                        product.stock == 0 ? "" : " ${product.stock}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: product.stock == 0
                              ? Colors.redAccent
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  from == true ? Divider() : SizedBox(),

                  // Order Button
                  // if (from)
                  //   Row(
                  //     children: [
                  //       Expanded(
                  //         child: Padding(
                  //           padding: const EdgeInsets.only(top: 6),
                  //           child: SizedBox(
                  //             height: 35,
                  //             child: ElevatedButton(
                  //               onPressed: product.stock == 0
                  //                   ? null
                  //                   : () {
                  //                       showOrderBottomSheet(
                  //                         context,
                  //                         product,
                  //                         productProvider,
                  //                       );
                  //                     },
                  //               style: ElevatedButton.styleFrom(
                  //                 backgroundColor: theme.colorScheme.primary,
                  //                 disabledBackgroundColor: Colors.grey.shade400,
                  //                 shape: RoundedRectangleBorder(
                  //                   borderRadius: BorderRadius.circular(20),
                  //                 ),
                  //                 padding: EdgeInsets.symmetric(horizontal: 12),
                  //               ),
                  //               child: Text(
                  //                 product.stock == 0 ? "OUT OF STOCK" : "ORDER",
                  //                 style: TextStyle(
                  //                   fontWeight: FontWeight.bold,
                  //                   color: theme.colorScheme.onPrimary,
                  //                 ),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildProductImage(String base64Image, {double size = 40}) {
  try {
    if (base64Image.isEmpty) {
      return Icon(Iconsax.camera, size: size, color: Colors.grey);
    }
    return Image.memory(
      base64Decode(base64Image),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  } catch (e) {
    return Icon(Icons.broken_image, size: size, color: Colors.red);
  }
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

class ImagePreviewPage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.memory(
                base64Decode(images[index]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
