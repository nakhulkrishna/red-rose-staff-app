import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff_app/order_products/provider/order.dart';
import 'package:url_launcher/url_launcher.dart';

/// -------------------------------
/// CATEGORY MODEL
/// -------------------------------
class Category {
  String id;
  String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {"id": id, "name": name};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map["id"] ?? "", name: map["name"] ?? "");
  }
}

class Order {
  final String orderId;
  final String salesManId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double total;
  final DateTime? timestamp;

  final String buyer; // new field

  Order({
    required this.orderId,
    required this.salesManId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
    this.timestamp,

    required this.buyer,
  });

  // Convert Firestore document -> Order model
  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    return Order(
      orderId: map['orderId'] ?? docId,
      salesManId: map['salesManId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toInt(),
      total: (map['total'] ?? 0).toDouble(),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,

      buyer: map['buyer'] ?? '', // new field mapping
    );
  }

  // Convert Order model -> Firestore document
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'salesManId': salesManId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'total': total,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,

      'buyer': buyer, // new field
    };
  }
}

/// -------------------------------
/// PRODUCT MODEL
/// -------------------------------
class Product {
  String id;
  String name;
  double price; // original price
  double? offerPrice; // ✅ new field (nullable)
  String unit;
  int stock;
  String description;
  List<String> images;
  String categoryId;
  double? hyperMarket;
  String market;
   String itemCode;

  Product({
    required this.itemCode,
    required this.market,
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.unit,
    required this.stock,
    required this.description,
    required this.images,
    required this.categoryId,
    this.hyperMarket,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemCode' : itemCode, 
      'market': market,
      "hyperPrice": hyperMarket,
      'id': id,
      'name': name,
      'price': price,
      'offerPrice': offerPrice, // ✅ save offer price too
      'unit': unit,
      'stock': stock,
      'description': description,
      'images': images,
      'categoryId': categoryId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Product(
      itemCode: map['itemCode'] ?? "",
      market: map['market'] ?? "",
      hyperMarket: parseDouble(map['hyperPrice']),
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: parseDouble(map['price']) ?? 0.0,
      offerPrice: parseDouble(map['offerPrice']),
      unit: map['unit'] ?? '',
      stock: parseInt(map['stock']),
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      categoryId: map['categoryId'] ?? '',
    );
  }
}

/// -------------------------------
/// PROVIDER
/// -------------------------------
class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ProductProvider() {
    listenProducts();
    listenCategories();
    listenOrders();
    fetchWhatsAppNumber();
  }
  List<Product> _selectedProducts = [];
  Map<String, int> _cartQuantity = {}; // key = product id, value = quantity
  Map<String, String> _cartWeight =
      {}; // key = product id, value = weight as string
  Map<String, String> _unitType =
      {}; // key = product id, value = 'Kg' or 'Cartoon'
  final Map<String, String> _weights = {};
  List<Product> get selectedProducts => _selectedProducts;
  final Map<String, TextEditingController> _controllers = {};

  // Get or create controller for a product
  TextEditingController weightController(String productId) {
    if (!_controllers.containsKey(productId)) {
      _controllers[productId] = TextEditingController(
        text: _weights[productId] ?? '',
      );
    }
    return _controllers[productId]!;
  }

  // select/deselect product
  void toggleProductSelection(String productId) {
    final index = _selectedProducts.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _selectedProducts.removeAt(index);
    } else {
      final product = filteredProducts.firstWhere((p) => p.id == productId);
      _selectedProducts.add(product);
      _unitType[productId] = 'Kg';
      _cartQuantity[productId] = 1;
      _cartWeight[productId] = '';
    }
    notifyListeners();
  }

  bool isProductSelected(String productId) =>
      _selectedProducts.any((p) => p.id == productId);

  // unit type
  String unitType(String productId) => _unitType[productId] ?? 'Kg';
  void setUnitType(String productId, String value) {
    _unitType[productId] = value;
    notifyListeners();
  }

  // quantity for cartoon
  int quantity(String productId) => _cartQuantity[productId] ?? 1;
  void setQuantity(String productId, int value) {
    _cartQuantity[productId] = value;
    notifyListeners();
  }

  // weight for kg
  String weight(String productId) => _cartWeight[productId] ?? '';
  void setWeight(String productId, String value) {
    _cartWeight[productId] = value;
    notifyListeners();
  }

  void clearSelections() {
    _selectedProducts.clear();
    _cartQuantity.clear();
    _cartWeight.clear();
    _unitType.clear();
    notifyListeners();
  }

  /// DATA
  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<Category> _categories = [];

  List<Product> get products => List.unmodifiable(_products);
  List<Order> get orders => List.unmodifiable(_orders);
  List<Category> get categories => List.unmodifiable(_categories);

  double get totalOrderValue {
    return _orders.fold(0.0, (sum, order) => sum + order.total);
  }

  /// STATE
  String searchQuery = "";
  String? selectedCategory; // stores categoryId
  String? expandedProductId;

  /// STREAM SUBSCRIPTIONS (to cancel later)
  StreamSubscription? _productSub;
  StreamSubscription? _ordersSub;
  StreamSubscription? _categorySub;

  /// -------------------------------
  /// STATE MANAGEMENT
  /// -------------------------------
  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    selectedCategory = categoryId;
    notifyListeners();
  }

  void toggleExpanded(String productId) {
    if (expandedProductId == productId) {
      expandedProductId = null;
    } else {
      expandedProductId = productId;
    }
    notifyListeners();
  }

  /// -------------------------------
  /// LIVE LISTEN TO PRODUCTS
  /// -------------------------------
  void listenProducts() {
    _productSub?.cancel(); // prevent duplicate listeners
    _productSub = _firestore.collection('products').snapshots().listen((
      snapshot,
    ) {
      _products
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Product.fromMap(doc.data())));
      notifyListeners();
    });
  }

  void listenOrders() async {
    _ordersSub?.cancel(); // prevent duplicate listeners
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userid = prefs.getString('user_id');
    _ordersSub = _firestore
        .collection('orders')
        .where('salesManId', isEqualTo: userid) // filter by logged-in user
        .snapshots()
        .listen((snapshot) {
          _orders
            ..clear()
            ..addAll(
              snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)),
            );
          notifyListeners();
        });
  }

  String? whatsappNumber;

  void fetchWhatsAppNumber() {
    _firestore
        .collection('order_whatsapp')
        .doc('main_number')
        .get()
        .then((doc) {
          if (doc.exists) {
            whatsappNumber = doc.data()?['number'] ?? '';
            notifyListeners();
          }
        })
        .catchError((error) {
          print("Error fetching WhatsApp number: $error");
        });
  }

  /// -------------------------------
  /// LIVE LISTEN TO CATEGORIES
  /// -------------------------------
  void listenCategories() {
    _categorySub?.cancel();
    _categorySub = _firestore.collection('categories').snapshots().listen((
      snapshot,
    ) {
      _categories
        ..clear()
        ..addAll(snapshot.docs.map((doc) => Category.fromMap(doc.data())));
      notifyListeners();
    });
  }

  /// -------------------------------
  /// FILTERED PRODUCTS
  /// -------------------------------
  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch =
          searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory =
          selectedCategory == null || p.categoryId == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// -------------------------------
  /// SEND ORDER TO WHATSAPP
  /// -------------------------------
  /// -------------------------------
  /// SEND ORDER TO WHATSAPP + SAVE IN FIRESTORE
  /// -------------------------------
Future<void> sendOrderWhatsAppMultiple(
  List<Map<String, dynamic>> selectedOrders,
  BuildContext context,
  String productBuyer, {
  required String salesManId,
}) async {
  final phoneNumber = whatsappNumber;

  if (phoneNumber == null || phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ WhatsApp number not available")),
    );
    return;
  }

  double grandTotal = 0;
  StringBuffer message = StringBuffer();

  // Header
  message.writeln("*ORDER INVOICE*");
  message.writeln("━━━━━━━━━━━━━━━━━━━━━━");
  message.writeln("Date: ${DateTime.now().toString().split(' ')[0]}");
  message.writeln("Customer: $productBuyer");
  message.writeln("━━━━━━━━━━━━━━━━━━━━━━");
  message.writeln();
  message.writeln("`Item           Qty    Price     Total      CODE`"); // Table header
  message.writeln("`-----------------------------------------------`");

  for (var item in selectedOrders) {
    Product product = item["product"];
    int qty = item["qty"];
    String? weight = item["weight"];

    double unitPrice = product.offerPrice ?? product.price;
    double total;
    String qtyDisplay;

    if (weight != null && weight.isNotEmpty) {
      double w = double.tryParse(weight) ?? 0;
      total = unitPrice * w;
      grandTotal += total;
      qtyDisplay = "${w.toStringAsFixed(2)}Kg";
    } else {
      total = unitPrice * qty;
      grandTotal += total;
      qtyDisplay = "$qty Carton";
    }

    // Format columns for alignment
    String itemName = product.name.length > 14
        ? product.name.substring(0, 14)
        : product.name.padRight(14);
    String qtyText = qtyDisplay.padLeft(5);
    String priceText = "₹${unitPrice.toStringAsFixed(0)}".padLeft(7);
    String totalText = "₹${total.toStringAsFixed(0)}".padLeft(7);
    String codeText = (product.itemCode ?? "").padLeft(8);

    // Add row
    message.writeln("`$itemName $qtyText $priceText $totalText $codeText`");

    // Update stock in Firestore
    final newStock = product.stock - qty;
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .update({'stock': newStock});
    product.stock = newStock;

    // Save order in Firestore
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();
    final order = Order(
      buyer: productBuyer,
      orderId: orderRef.id,
      salesManId: salesManId,
      productId: product.id,
      productName: product.name,
      price: unitPrice,
      quantity: weight != null && weight.isNotEmpty
          ? (double.tryParse(weight) ?? 0).toInt()
          : qty,
      total: total,
      timestamp: DateTime.now(),
    );
    await orderRef.set(order.toMap());
  }

  // Footer
  message.writeln("━━━━━━━━━━━━━━━━━━━━━━");
  message.writeln("*Grand Total:* ₹${grandTotal.toStringAsFixed(0)}");


  final url = Uri.parse(
    "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message.toString())}",
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw "Could not launch WhatsApp";
  }
}

  /// -------------------------------
  /// CLEAN UP LISTENERS
  /// -------------------------------
  @override
  void dispose() {
    _productSub?.cancel();
    _categorySub?.cancel();
    super.dispose();
  }
}
