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
        return true;
      },
      child: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          final products = provider.filteredProducts;
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Products", style: TextStyle(fontSize: 20)),
                  if (buyername.isNotEmpty)
                    Text(
                      "Ordering for: $buyername",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) => provider.setSearchQuery(value),
                          decoration: InputDecoration(
                            hintText: "Search products by name...",
                            prefixIcon: Icon(
                              Iconsax.search_normal_1,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: provider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () =>
                                        provider.setSearchQuery(''),
                                  )
                                : null,
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Category Chips
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected =
                                provider.selectedCategory == null;
                            return _buildCategoryChip(
                              context,
                              "All",
                              isSelected,
                              () => provider.setCategory(null),
                              icon: Iconsax.category,
                            );
                          }

                          final cat = provider.categories[index - 1];
                          final isSelected =
                              provider.selectedCategory == cat.name;

                          return _buildCategoryChip(
                            context,
                            cat.name,
                            isSelected,
                            () => provider.setCategory(cat.name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: products.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: [
                      // Results count
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              "${products.length} Products",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (provider.selectedProducts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.shopping_cart,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${provider.selectedProducts.length} selected",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Products List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return ModernProductCard(
                              from: isThisFormCustomers,
                              productProvider: provider,
                              product: product,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            floatingActionButton: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.selectedProducts.isEmpty)
                  return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FloatingActionButton.extended(
                      backgroundColor: theme.colorScheme.primary,
                      elevation: 4,
                      onPressed: () async {
                        List<SelectedOrder> orders = provider.selectedProducts
                            .map((element) {
                              return SelectedOrder(
                                product: element,
                                quantity: 0,
                                buyer: buyername,
                              );
                            })
                            .toList();

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

                        if (orderPlaced != true) {
                          provider.clearSelections();
                        }
                      },
                      icon: const Icon(Iconsax.shopping_cart, size: 24),
                      label: Text(
                        "Continue with ${provider.selectedProducts.length} Item${provider.selectedProducts.length > 1 ? 's' : ''}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'asstes/Image-3.png',
            width: 220,
            height: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            "No products found",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ModernProductCard extends StatelessWidget {
  final bool from;
  final ProductProvider productProvider;
  final Product product;

  const ModernProductCard({
    super.key,
    required this.product,
    required this.productProvider,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = productProvider.isProductSelected(product.id);
    final isOutOfStock = product.stock == 0;

    return GestureDetector(
      onTap: from && !isOutOfStock
          ? () => productProvider.toggleProductSelection(product.id)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  GestureDetector(
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
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              (product.images == null ||
                                  product.images.isEmpty ||
                                  product.images.first.isEmpty)
                              ? Icon(
                                  Iconsax.image,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                )
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      product.images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Iconsax.gallery_slash,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    if (isOutOfStock)
                                      Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: const Center(
                                          child: Text(
                                            "OUT OF\nSTOCK",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        AutoSizeText(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isOutOfStock
                                ? Colors.grey
                                : theme.colorScheme.onBackground,
                          ),
                          maxLines: 2,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.categoryId,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Pricing
                        Row(
                          children: [
                            if (product.offerPrice != null) ...[
                              Text(
                                "QR ${product.price.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              "QR ${(product.offerPrice ?? product.price).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: product.offerPrice != null
                                    ? Colors.green.shade700
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Hypermarket & Stock
                        Row(
                          children: [
                            if (product.hyperMarket != null) ...[
                              Icon(
                                Iconsax.shop,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Hyper: QR ${product.hyperMarket!.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],

                            Text(
                              "Stock: ${product.stock}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOutOfStock
                                    ? Colors.red
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Selection Checkbox Overlay
            if (from && !isOutOfStock)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            clipBehavior: Clip.none,
            panEnabled: true,
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
