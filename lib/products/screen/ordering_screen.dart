import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/order_products/provider/order.dart';
import 'package:staff_app/products/provider/products_management.dart';

class OrderScreen extends StatefulWidget {
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
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _selectedUnits = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    for (var product in widget.products) {
      _controllers[product.id] = TextEditingController(text: '1');
      _focusNodes[product.id] = FocusNode();

      // Set default unit based on available prices
      if (product.kgPrice != null && product.kgPrice! > 0) {
        _selectedUnits[product.id] = 'Kg';
      } else if (product.pcsPrice != null && product.pcsPrice! > 0) {
        _selectedUnits[product.id] = 'Piece';
      } else if (product.ctrPrice != null && product.ctrPrice! > 0) {
        _selectedUnits[product.id] = 'Cartoon';
      } else {
        _selectedUnits[product.id] = 'Piece';
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  double _getUnitPrice(Product product, String unit) {
    switch (unit) {
      case 'Kg':
        return product.kgPrice ?? product.offerPrice ?? product.price;
      case 'Piece':
        return product.pcsPrice ?? product.offerPrice ?? product.price;
      case 'Cartoon':
        return product.ctrPrice ?? product.offerPrice ?? product.price;
      default:
        return product.offerPrice ?? product.price;
    }
  }

  double _getProductTotal(Product product) {
    final controller = _controllers[product.id];
    final quantity = double.tryParse(controller?.text ?? '0') ?? 0;
    final unit = _selectedUnits[product.id] ?? 'Piece';
    final unitPrice = _getUnitPrice(product, unit);
    return quantity * unitPrice;
  }

  double get _grandTotal {
    double total = 0;
    for (var product in widget.products) {
      total += _getProductTotal(product);
    }
    return total;
  }

  List<String> _getAvailableUnits(Product product) {
    List<String> units = [];
    if (product.kgPrice != null && product.kgPrice! > 0) units.add('Kg');
    if (product.pcsPrice != null && product.pcsPrice! > 0) units.add('Piece');
    if (product.ctrPrice != null && product.ctrPrice! > 0) units.add('Cartoon');

    if (units.isEmpty) units.add('Piece');
    return units;
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, false);
          return false;
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  widget.buyername,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Items count banner
              GestureDetector(
                onTap: _dismissKeyboard,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.shopping_bag,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${widget.products.length} items selected",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Products List
              Expanded(
                child: ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: widget.products.length,
                  itemBuilder: (context, index) {
                    final product = widget.products[index];
                    final isLast = index == widget.products.length - 1;

                    return QuickOrderCard(
                      product: product,
                      controller: _controllers[product.id]!,
                      focusNode: _focusNodes[product.id]!,
                      selectedUnit: _selectedUnits[product.id] ?? 'Piece',
                      availableUnits: _getAvailableUnits(product),
                      onUnitChanged: (newUnit) {
                        _dismissKeyboard();
                        setState(() {
                          _selectedUnits[product.id] = newUnit;
                        });
                      },
                      onQuantityChanged: () {
                        setState(() {});
                      },
                      getUnitPrice: (unit) => _getUnitPrice(product, unit),
                      getTotal: () => _getProductTotal(product),
                      isLast: isLast,
                    );
                  },
                ),
              ),
            ],
          ),

          // Bottom Summary and Place Order
          bottomNavigationBar: GestureDetector(
            onTap: _dismissKeyboard,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Amount",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "QR ${_grandTotal.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.wallet_3,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Place Order Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () {
                            _dismissKeyboard();
                            _placeOrder(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: isDark
                                ? theme.colorScheme.background
                                : theme.colorScheme.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.tick_circle,
                                size: 22,
                                color: isDark
                                    ? theme.colorScheme.background
                                    : theme.colorScheme.surface,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Place Order",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: isDark
                                      ? theme.colorScheme.background
                                      : theme.colorScheme.surface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Unfocus any active text field
    FocusScope.of(context).unfocus();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.green.shade300 : Colors.green)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.tick_square,
                color: isDark ? Colors.green.shade300 : Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                "Confirm Order",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade700.withOpacity(0.5)
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.user,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.buyername,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Items:",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${widget.products.length}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grand Total:",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "QR ${_grandTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: isDark
                  ? theme.colorScheme.background
                  : theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Confirm",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? theme.colorScheme.background
                    : theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Card(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Processing order...",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final userid = prefs.getString('user_id') ?? "";
        final provider = Provider.of<ProductProvider>(context, listen: false);

        List<Map<String, dynamic>> selectedOrders = [];

        for (var product in widget.products) {
          final controller = _controllers[product.id];
          final qty = double.tryParse(controller?.text ?? '0') ?? 0;

          if (qty <= 0) continue;

          final unit = _selectedUnits[product.id] ?? 'Piece';
          final unitPrice = _getUnitPrice(product, unit);

          selectedOrders.add({
            "product": product,
            "qty": qty,
            "unit": unit,
            "unitPrice": unitPrice,
            "total": qty * unitPrice,
          });
        }

        if (selectedOrders.isEmpty) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Please enter quantities for at least one item",
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        await provider.sendOrderWhatsAppMultiple(
          selectedOrders,
          context,
          widget.buyername,
          salesManId: userid,
        );

        Navigator.pop(context);
        provider.clearSelections();
        Navigator.pop(context, true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Order placed successfully!",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class QuickOrderCard extends StatelessWidget {
  final Product product;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String selectedUnit;
  final List<String> availableUnits;
  final Function(String) onUnitChanged;
  final VoidCallback onQuantityChanged;
  final double Function(String) getUnitPrice;
  final double Function() getTotal;
  final bool isLast;

  const QuickOrderCard({
    super.key,
    required this.product,
    required this.controller,
    required this.focusNode,
    required this.selectedUnit,
    required this.availableUnits,
    required this.onUnitChanged,
    required this.onQuantityChanged,
    required this.getUnitPrice,
    required this.getTotal,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isKg = selectedUnit == 'Kg';

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  height: 75,
                  width: 75,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Iconsax.gallery,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.4),
                              size: 30,
                            ),
                          )
                        : Icon(
                            Iconsax.gallery,
                            size: 30,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.4),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Unit Selector
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedUnit,
                            isDense: true,
                            dropdownColor: theme.cardColor,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            items: availableUnits.map((unit) {
                              IconData icon = unit == 'Kg'
                                  ? Iconsax.weight
                                  : unit == 'Piece'
                                  ? Iconsax.box_1
                                  : Iconsax.box;
                              return DropdownMenuItem(
                                value: unit,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(unit),
                                    const SizedBox(width: 5),
                                    Text(
                                      "• QR ${getUnitPrice(unit).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                onUnitChanged(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quantity Input
            TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: isKg
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                if (!isKg) FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) => onQuantityChanged(),
              onSubmitted: (_) {
                focusNode.unfocus();
              },
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
              decoration: InputDecoration(
                labelText: isKg ? "Weight" : "Quantity",
                hintText: isKg ? "e.g., 1.5" : "e.g., 5",
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  fontWeight: FontWeight.normal,
                ),
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(
                  isKg ? Iconsax.weight_1 : Iconsax.box_1,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                suffixText: selectedUnit,
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                filled: true,
                fillColor: isDark
                    ? theme.colorScheme.primary.withOpacity(0.05)
                    : theme.colorScheme.primary.withOpacity(0.03),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Total Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "QR ${getTotal().toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
