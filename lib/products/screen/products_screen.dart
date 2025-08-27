import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/products/provider/products_management.dart';
import 'package:staff_app/theme/colors.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        final products = provider.filteredProducts;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text("Products"),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          body: Column(
            children: [
              // 🔹 Category chips
              SizedBox(
                height: 50,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                    final isSelected = provider.selectedCategory == cat.name;

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
                    ? const Center(child: Text("No products found"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.55,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            productProvider: provider,
                            product: product,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductProvider productProvider;
  final Product product;
  // final String name;
  // final String price;
  // final List<String> images;
  // final String tag;
  // final int stock;

  const ProductCard({
    super.key,
    // required this.name,
    // required this.price,
    // required this.images,
    // required this.tag,
    // required this.stock,
    required this.product,
    required this.productProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor, // ✅ adapts to dark/light
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Product Images
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                itemCount: product.images.length,
                itemBuilder: (context, index) {
                  return Image.memory(
                    base64Decode(product.images[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 🔹 Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.categoryId,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 🔹 Product Name
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Column(
            children: [
              product.offerPrice == null
                  ? Text(
                      product.price.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade200,
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          product.price.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade200,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          product.offerPrice.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
            ],
          ),

          Text(
            product.stock == 0 ? "Out of Stock" : product.stock.toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: product.stock == 0
                  ? Colors.grey.shade600
                  : theme.colorScheme.primary,
            ),
          ),
          const Spacer(),

          // 🔹 Price + Order button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      showOrderBottomSheet(context, product, productProvider);
                    },
                    child: Text(
                      "ORDER",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

void showOrderBottomSheet(
  BuildContext parentcontext,
  Product product,
  ProductProvider provider,
) {
  int quantity = 1;
  String selectedColor = "";
  String productBuyer = "";
  String selectedShop = "";

  // Error messages
  String? quantityError;
  String? colorError;
  String? buyerError;
  String? shopError;

  final theme = Theme.of(parentcontext);

  showModalBottomSheet(
    context: parentcontext,
    isScrollControlled: true,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Product Name & Price
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "₹ ${product.price} / ${product.unit}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Product Images Horizontal Scroll
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildProductImage(
                            product.images[index],
                            size: 70,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Quantity (${product.unit})",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setModalState(() {
                                  quantity--;
                                  quantityError = null;
                                });
                              }
                            },
                            icon: Icon(
                              Icons.remove_circle,
                              color: theme.colorScheme.error,
                              size: 28,
                            ),
                          ),
                          Text(
                            "$quantity",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                if (quantity < product.stock) {
                                  quantity++;
                                  quantityError = null;
                                } else {
                                  quantityError =
                                      "⚠️ Not enough stock available";
                                }
                              });
                            },
                            icon: Icon(
                              Icons.add_circle,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (quantityError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        quantityError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Color Input Field
                  TextField(
                    keyboardType: TextInputType.text,
                    autocorrect: true,
                    autofocus: true,
                    enableSuggestions: true,
                    enableIMEPersonalizedLearning: true,

                    onChanged: (value) => setModalState(() {
                      selectedColor = value;
                      colorError = null;
                    }),
                    decoration: InputDecoration(
                      labelText: "Color",
                      hintText: "Enter product color",
                      errorText: colorError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buyer Input Field
                  TextField(
                       keyboardType: TextInputType.text,
                    autocorrect: true,
                    autofocus: true,
                    enableSuggestions: true,
                    enableIMEPersonalizedLearning: true,
                    onChanged: (value) => setModalState(() {
                      productBuyer = value;
                      buyerError = null;
                    }),
                    decoration: InputDecoration(
                      labelText: "Buyer",
                      hintText: "Enter product Buyer",
                      errorText: buyerError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₹ ${(product.price * quantity).toStringAsFixed(2)}",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Select Shop
                  Text(
                    "Select Shop",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedShop == "Hyper Market"
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedShop = "Hyper Market";
                            shopError = null;
                          });
                        },
                        child: Text(
                          "Hyper Market",
                          style: TextStyle(
                            color: selectedShop == "Hyper Market"
                                ? theme.colorScheme.surface
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedShop == "Local Market"
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedShop = "Local Market";
                            shopError = null;
                          });
                        },
                        child: Text(
                          "Local Market",
                          style: TextStyle(
                            color: selectedShop == "Local Market"
                                ? theme.colorScheme.surface
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (shopError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        shopError!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),

                  const SizedBox(height: 25),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        bool hasError = false;

                        setModalState(() {
                          if (quantity < 1) {
                            quantityError = "⚠️ Please select at least 1 quantity";
                            hasError = true;
                          }
                          if (selectedColor.isEmpty) {
                            colorError = "⚠️ Please enter a color";
                            hasError = true;
                          }
                          if (productBuyer.isEmpty) {
                            buyerError = "⚠️ Please enter Buyer";
                            hasError = true;
                          }
                          if (selectedShop.isEmpty) {
                            shopError = "⚠️ Please select shop";
                            hasError = true;
                          }
                        });

                        if (!hasError) {
                          // Confirmation dialog
                          showDialog(
                            context: parentcontext,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Confirm Order"),
                              content: Text(
                                "Do you want to place order for "
                                "$quantity × ${product.name} "
                                "(${selectedColor}) at ₹ ${(product.price * quantity).toStringAsFixed(2)}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.pop(parentcontext);
                                    provider.sendOrderWhatsApp(
                                      product,
                                      quantity,
                                      parentcontext,
                                      salesManId: "01",
                                      selectedColor,
                                      productBuyer,
                                    );
                                  },
                                  child: Text(
                                    "Yes, Place Order",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.send, color: theme.colorScheme.primary),
                      label: Text(
                        "Place Order",
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
