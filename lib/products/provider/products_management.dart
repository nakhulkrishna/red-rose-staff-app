import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  final String color; // new field
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
    required this.color,
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
      color: map['color'] ?? '',       // new field mapping
      buyer: map['buyer'] ?? '',       // new field mapping
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
      'color': color, // new field
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

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.unit,
    required this.stock,
    required this.description,
    required this.images,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
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
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      offerPrice: map['offerPrice'] != null
          ? (map['offerPrice'] as num).toDouble()
          : null, // ✅ load offer price if exists
      unit: map['unit'] ?? '',
      stock: map['stock'] ?? 0,
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

void listenOrders() {
  _ordersSub?.cancel(); // prevent duplicate listeners
  _ordersSub = _firestore.collection('orders').snapshots().listen((snapshot) {
    _orders
      ..clear()
      ..addAll(snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)));
    notifyListeners();
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
  Future<void> sendOrderWhatsApp(
    Product product,
    int qty,
  
    BuildContext context,   String color, String productBuyer , {
    required String salesManId, // ✅ pass salesman id when calling
  }) async {
    // const phoneNumber = "97477270580";
    const phoneNumber = "919400621538";
    double total = product.price * qty;

    if (product.stock < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Not enough stock available")),
      );
      return;
    }

    // -------------------------------
    // Build WhatsApp Message
    // -------------------------------
    String message =
        """
🛒 *New Order*
━━━━━━━━━━━━━━
📦 *Product*: ${product.name}

🏷 *Category*: ${product.categoryId}

💰 *Price*: ₹${product.price} per ${product.unit}

❄️ *Selected Colors*: $color

🧑‍💼 *Buyer* $productBuyer

🔢 *Quantity Ordered*: $qty ${product.unit}
━━━━━━━━━━━━━━
✅ *Total*: ₹$total

📦 *Stock Left After*: ${product.stock - qty} ${product.unit}
""";

    final url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // -------------------------------
      // Update product stock
      // -------------------------------
      final newStock = product.stock - qty;
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .update({'stock': newStock});

      product.stock = newStock;
      notifyListeners();

      // -------------------------------
      // Save Order in Firestore
      // -------------------------------
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orders = Order(
        color: color,
        buyer: productBuyer,
        orderId: orderRef.id,
        salesManId: salesManId,
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: qty,
        total: total,
         timestamp: DateTime.now(),
      );
      await orderRef.set(orders.toMap());
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
