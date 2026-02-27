import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.code,
    required super.name,
    required super.description,
    required super.category,
    required super.imageUrl,
    required super.baseUnit,
    required super.marketPrices,
    required super.units,
    required super.priceQar,
    required super.offerPriceQar,
    required super.availableStock,
    required super.imageUrls,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    final baseUnit = _readKeyOrValue(map['baseUnit'], fallback: 'piece');
    final productCode =
        (map['productCode'] as String?) ?? (map['code'] as String?) ?? id;
    final productName =
        (map['productName'] as String?) ??
        (map['name'] as String?) ??
        'Unnamed';
    final productDescription =
        (map['productDescription'] as String?) ??
        (map['description'] as String?) ??
        '';
    final categoryName = _readCategory(map['category']);

    final metrics = (map['metrics'] as Map<String, dynamic>?) ?? const {};
    final inventory = (map['inventory'] as Map<String, dynamic>?) ?? const {};
    final images = (map['images'] as Map<String, dynamic>?) ?? const {};
    final imageUrls =
        (images['urls'] as List?)
            ?.whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .toList() ??
        <String>[];
    final primaryImage =
        (images['primaryUrl'] as String?) ??
        (map['imageUrl'] as String?) ??
        (imageUrls.isNotEmpty ? imageUrls.first : '');

    final marketPrices = _readMarketPrices(map, baseUnit);
    final units = _readSaleUnits(map['saleUnits'], baseUnit);

    final displayPrice =
        (metrics['displayPriceQar'] as num?)?.toDouble() ??
        marketPrices[MarketType.hyper] ??
        0;
    final displayOffer =
        (metrics['displayOfferPriceQar'] as num?)?.toDouble() ?? 0;
    final availableQty =
        (inventory['availableQtyBaseUnit'] as num?)?.toDouble() ?? 0;

    return ProductModel(
      id: id,
      code: productCode,
      name: productName,
      description: productDescription,
      category: categoryName,
      imageUrl: primaryImage,
      baseUnit: baseUnit,
      marketPrices: marketPrices,
      units: units,
      priceQar: displayPrice,
      offerPriceQar: displayOffer,
      availableStock: availableQty,
      imageUrls: [
        ...imageUrls,
        if (primaryImage.isNotEmpty && !imageUrls.contains(primaryImage))
          primaryImage,
      ],
    );
  }
}

String _readCategory(dynamic category) {
  if (category is Map<String, dynamic>) {
    return (category['name'] as String?) ??
        (category['key'] as String?) ??
        'General';
  }
  if (category is String && category.trim().isNotEmpty) return category;
  return 'General';
}

String _readKeyOrValue(dynamic value, {required String fallback}) {
  if (value is Map<String, dynamic>) {
    return (value['name'] as String?) ?? (value['key'] as String?) ?? fallback;
  }
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

List<ProductUnit> _readSaleUnits(dynamic saleUnits, String baseUnit) {
  if (saleUnits is List && saleUnits.isNotEmpty) {
    return saleUnits.whereType<Map<String, dynamic>>().map((unitMap) {
      final unitName =
          (unitMap['name'] as String?) ??
          (unitMap['key'] as String?) ??
          baseUnit;
      final multiplier =
          (unitMap['conversionToBaseUnit'] as num?)?.toDouble() ?? 1.0;
      return ProductUnit(
        code: unitName,
        multiplierToBase: multiplier,
        allowDecimal: true,
      );
    }).toList();
  }
  return [ProductUnit(code: baseUnit, multiplierToBase: 1, allowDecimal: true)];
}

Map<MarketType, double> _readMarketPrices(
  Map<String, dynamic> map,
  String baseUnit,
) {
  final pricing = (map['pricing'] as Map<String, dynamic>?) ?? const {};
  final markets = (pricing['markets'] as Map<String, dynamic>?) ?? const {};
  final defaultMarketKey = pricing['defaultMarketKey'] as String?;
  Map<String, dynamic>? selectedMarket;
  if (defaultMarketKey != null) {
    final value = markets[defaultMarketKey];
    if (value is Map<String, dynamic>) {
      selectedMarket = value;
    }
  }
  if (selectedMarket == null) {
    for (final value in markets.values) {
      if (value is Map<String, dynamic>) {
        selectedMarket = value;
        break;
      }
    }
  }
  final prices =
      (selectedMarket?['prices'] as Map<String, dynamic>?) ?? const {};

  double priceFromUnit(String keyOrName) {
    final entry = prices[keyOrName];
    if (entry is Map<String, dynamic>) {
      final offer =
          (entry['autoOfferPriceQar'] as num?)?.toDouble() ??
          (entry['manualOfferPriceQar'] as num?)?.toDouble();
      final regular =
          (entry['autoPriceQar'] as num?)?.toDouble() ??
          (entry['manualPriceQar'] as num?)?.toDouble() ??
          0;
      return offer ?? regular;
    }
    return 0;
  }

  final byBase = priceFromUnit(baseUnit);
  return {MarketType.hyper: byBase, MarketType.local: byBase};
}
