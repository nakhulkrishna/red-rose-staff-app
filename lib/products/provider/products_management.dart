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
  double price; // original base price (optional, keep for legacy)
  double? offerPrice; // ✅ optional offer price
  String unit;
  int stock;
  String description;
  List<String> images;
  String categoryId;
  double? hyperMarket;
  String market;
  String itemCode;

  // ✅ new fields
  double? kgPrice;
  double? ctrPrice;
  double? pcsPrice;

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
    this.kgPrice,
    this.ctrPrice,
    this.pcsPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemCode': itemCode,
      'market': market,
      'hyperPrice': hyperMarket,
      'id': id,
      'name': name,
      'price': price,
      'offerPrice': offerPrice,
      'unit': unit,
      'stock': stock,
      'description': description,
      'images': images,
      'categoryId': categoryId,

      // ✅ save new fields
      'kgPrice': kgPrice,
      'ctrPrice': ctrPrice,
      'pcsPrice': pcsPrice,
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

      // ✅ parse new fields
      kgPrice: parseDouble(map['kgPrice']),
      ctrPrice: parseDouble(map['ctrPrice']),
      pcsPrice: parseDouble(map['pcsPrice']),
    );
  }
}

/// -------------------------------
/// PROVIDER
/// -------------------------------
class ProductProvider extends ChangeNotifier {
void calculateTotal(String productId, Product product) {
  final unit = _unitType[productId] ?? 'Kg';
  double total = 0;

  switch (unit) {
    case 'Kg':
      final kg = double.tryParse(_kgControllers[productId]?.text ?? "0") ?? 0;
      final kgPrice = product.kgPrice ?? product.offerPrice ?? product.price;
      total = kg * kgPrice;
      break;

    case 'Piece':
      final pcs =
          double.tryParse(_pieceControllers[productId]?.text ?? "0") ?? 0;
      final pcsPrice = product.pcsPrice ?? product.offerPrice ?? product.price;
      total = pcs * pcsPrice;
      break;

    case 'Cartoon':
      final ctr =
          double.tryParse(_ctrControllers[productId]?.text ?? "0") ?? 0;
      final ctrPrice = product.ctrPrice ?? product.offerPrice ?? product.price;
      total = ctr * ctrPrice;
      break;
  }

  _totals[productId] = total;
  notifyListeners();
}

  Map<String, TextEditingController> _kgControllers = {};
  Map<String, TextEditingController> _kgPriceControllers = {};
  Map<String, TextEditingController> _ctrControllers = {};
  Map<String, TextEditingController> _ctrPriceControllers = {};
  Map<String, TextEditingController> _pieceControllers = {};
  Map<String, TextEditingController> _piecePriceControllers = {};

  Map<String, double> _totals = {};

  TextEditingController kgController(String pid) =>
      _kgControllers.putIfAbsent(pid, () => TextEditingController());
  TextEditingController kgPriceController(String pid) =>
      _kgPriceControllers.putIfAbsent(pid, () => TextEditingController());
  TextEditingController ctrController(String pid) =>
      _ctrControllers.putIfAbsent(pid, () => TextEditingController());
  TextEditingController ctrPriceController(String pid) =>
      _ctrPriceControllers.putIfAbsent(pid, () => TextEditingController());
  TextEditingController pieceController(String pid) =>
      _pieceControllers.putIfAbsent(pid, () => TextEditingController());
  TextEditingController piecePriceController(String pid) =>
      _piecePriceControllers.putIfAbsent(pid, () => TextEditingController());

  // void calculateTotal(String pid) {
  //   final kg = double.tryParse(_kgControllers[pid]?.text ?? "0") ?? 0;
  //   final kgPrice = double.tryParse(_kgPriceControllers[pid]?.text ?? "0") ?? 0;
  //   final ctr = double.tryParse(_ctrControllers[pid]?.text ?? "0") ?? 0;
  //   final ctrPrice = double.tryParse(_ctrPriceControllers[pid]?.text ?? "0") ?? 0;
  //   final piece = double.tryParse(_pieceControllers[pid]?.text ?? "0") ?? 0;
  //   final piecePrice = double.tryParse(_piecePriceControllers[pid]?.text ?? "0") ?? 0;

  //   _totals[pid] = (kg * kgPrice) + (ctr * ctrPrice) + (piece * piecePrice);
  //   notifyListeners();
  // }

  double productTotal(String pid) => _totals[pid] ?? 0;

  double get grandTotal => _totals.values.fold(0, (sum, item) => sum + item);

  List<Map<String, dynamic>> buildFinalOrders(List<Product> products) {
    return products
        .map((p) {
          return {
            "productId": p.id,
            "name": p.name,
            "total": productTotal(p.id),
            "kg": _kgControllers[p.id]?.text,
            "kgPrice": _kgPriceControllers[p.id]?.text,
            "ctr": _ctrControllers[p.id]?.text,
            "ctrPrice": _ctrPriceControllers[p.id]?.text,
            "pieces": _pieceControllers[p.id]?.text,
            "piecePrice": _piecePriceControllers[p.id]?.text,
          };
        })
        .where((o) => (o["total"] ?? 0) == 0)
        .toList();
  }

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
 List<Map<String, dynamic>> orders,
  BuildContext context,
  String buyerName, {
  required String salesManId,
}) async {
  final phoneNumber = whatsappNumber;

  if (phoneNumber == null || phoneNumber.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ WhatsApp number not available")),
    );
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final salesMan = prefs.getString('username') ?? '';

  double grandTotal = 0;
  StringBuffer message = StringBuffer();

  // Header
  message.writeln("*$salesMan*");
  message.writeln("━━━━━━━━━━━━━━━━━━━━━━");
  message.writeln("Date: ${DateTime.now().toString().split(' ')[0]}");
  message.writeln("Customer: $buyerName");
  message.writeln("━━━━━━━━━━━━━━━━━━━━━━");
  message.writeln();
  message.writeln("`Item           Qty    UnitPrice   Total      CODE`");
  message.writeln("`---------------------------------------------------`");

  for (var product in selectedProducts) {
    final pid = product.id;
    final unit = unitType(pid);

    double quantity = 0;
    double unitPrice = 0;

    // Determine quantity and unit price based on selected unit
    switch (unit) {
      case 'Kg':
        quantity = double.tryParse(_kgControllers[pid]?.text ?? "0") ?? 0;
        unitPrice = product.kgPrice ?? product.offerPrice ?? product.price;
        break;
      case 'Piece':
        quantity = double.tryParse(_pieceControllers[pid]?.text ?? "0") ?? 0;
        unitPrice = product.pcsPrice ?? product.offerPrice ?? product.price;
        break;
      case 'Cartoon':
        quantity = double.tryParse(_ctrControllers[pid]?.text ?? "0") ?? 0;
        unitPrice = product.ctrPrice ?? product.offerPrice ?? product.price;
        break;
    }

    double total = quantity * unitPrice;
    grandTotal += total;

    String qtyDisplay = unit == 'Kg'
        ? "${quantity.toStringAsFixed(2)} Kg"
        : unit == 'Piece'
            ? "${quantity.toInt()} pcs"
            : "${quantity.toInt()} ctr";

    // Format columns
    String itemName =
        product.name.length > 14 ? product.name.substring(0, 14) : product.name.padRight(14);
    String qtyText = qtyDisplay.padLeft(8);
    String priceText = "QR ${unitPrice.toStringAsFixed(2)}".padLeft(10);
    String totalText = "QR ${total.toStringAsFixed(2)}".padLeft(10);
    String codeText = (product.itemCode).padLeft(8);

    message.writeln("`$itemName $qtyText $priceText $totalText $codeText`");

    // Update stock in Firestore
    final newStock = product.stock - quantity.toInt();
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .update({'stock': newStock});
    product.stock = newStock;

    // Save order in Firestore
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();
    await orderRef.set({
      "buyer": buyerName,
      "orderId": orderRef.id,
      "salesManId": salesManId,
      "productId": product.id,
      "productName": product.name,
      "unit": unit,
      "quantity": quantity,
      "unitPrice": unitPrice,
      "total": total,
      "timestamp": DateTime.now(),
    });
  }

  // Footer
  message.writeln("━━━━━━━━━━━━━━━━━━━━━━");
  message.writeln("*Grand Total:* QR${grandTotal.toStringAsFixed(2)}");

  final url = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message.toString())}");

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
