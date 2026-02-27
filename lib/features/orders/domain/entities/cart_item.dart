class CartItem {
  final String lineId;
  final String productId;
  final String productCode;
  final String productName;
  final String unitCode;
  final bool allowDecimal;
  final double multiplierToBase;
  final double quantity;
  final double unitPrice;
  final double regularPriceQar;
  final double offerPriceQar;
  final double appliedPriceQar;

  const CartItem({
    required this.lineId,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unitCode,
    required this.allowDecimal,
    required this.multiplierToBase,
    required this.quantity,
    required this.unitPrice,
    required this.regularPriceQar,
    required this.offerPriceQar,
    required this.appliedPriceQar,
  });

  double get total => quantity * unitPrice;
  double get baseQuantity => quantity * multiplierToBase;

  CartItem copyWith({
    String? productCode,
    String? unitCode,
    bool? allowDecimal,
    double? multiplierToBase,
    double? quantity,
    double? unitPrice,
    double? regularPriceQar,
    double? offerPriceQar,
    double? appliedPriceQar,
  }) {
    return CartItem(
      lineId: lineId,
      productId: productId,
      productCode: productCode ?? this.productCode,
      productName: productName,
      unitCode: unitCode ?? this.unitCode,
      allowDecimal: allowDecimal ?? this.allowDecimal,
      multiplierToBase: multiplierToBase ?? this.multiplierToBase,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      regularPriceQar: regularPriceQar ?? this.regularPriceQar,
      offerPriceQar: offerPriceQar ?? this.offerPriceQar,
      appliedPriceQar: appliedPriceQar ?? this.appliedPriceQar,
    );
  }
}
