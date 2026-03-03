import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';

class ProductModel extends Product {
  static const int _maxImageUrlsPerProduct = 6;

  const ProductModel({
    required super.id,
    required super.code,
    required super.name,
    required super.description,
    required super.category,
    required super.imageUrl,
    required super.baseUnit,
    required super.marketPrices,
    required super.marketUnitPrices,
    required super.marketUnitOfferPrices,
    required super.units,
    required super.priceQar,
    required super.offerPriceQar,
    required super.availableStock,
    required super.imageUrls,
    required super.hasMarketPriceConfigured,
  });

  factory ProductModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    required String salesMarketKey,
  }) {
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

    final inventory = (map['inventory'] as Map<String, dynamic>?) ?? const {};
    final images = (map['images'] as Map<String, dynamic>?) ?? const {};
    final imageUrls =
        (images['urls'] as List?)
            ?.whereType<String>()
            .where((url) => url.trim().isNotEmpty)
            .take(_maxImageUrlsPerProduct)
            .toList() ??
        <String>[];
    final primaryImage =
        (images['primaryUrl'] as String?) ??
        (map['imageUrl'] as String?) ??
        (imageUrls.isNotEmpty ? imageUrls.first : '');

    final selectedMarket =
        _marketTypeFromKey(salesMarketKey) ?? MarketType.local;
    final marketPrices = _readMarketPrices(
      map,
      baseUnit,
      salesMarketKey: salesMarketKey,
      selectedMarket: selectedMarket,
    );
    final marketUnitPrices = _readMarketUnitPrices(
      map,
      useOfferPrice: false,
      salesMarketKey: salesMarketKey,
      selectedMarket: selectedMarket,
    );
    final marketUnitOfferPrices = _readMarketUnitPrices(
      map,
      useOfferPrice: true,
      salesMarketKey: salesMarketKey,
      selectedMarket: selectedMarket,
    );
    final units = _readSaleUnits(map['saleUnits'], baseUnit);

    final hasMarketPriceConfigured =
        marketPrices[selectedMarket] != null &&
        marketPrices[selectedMarket]! > 0;
    final baseUnitKey = _normalizeUnitKey(baseUnit);
    final displayPrice = marketPrices[selectedMarket] ?? 0;
    final displayOffer =
        marketUnitOfferPrices[selectedMarket]?[baseUnitKey] ?? 0;
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
      marketUnitPrices: marketUnitPrices,
      marketUnitOfferPrices: marketUnitOfferPrices,
      units: units,
      priceQar: displayPrice,
      offerPriceQar: displayOffer,
      availableStock: availableQty,
      hasMarketPriceConfigured: hasMarketPriceConfigured,
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
  String baseUnit, {
  required String salesMarketKey,
  required MarketType selectedMarket,
}) {
  final pricing = (map['pricing'] as Map<String, dynamic>?) ?? const {};
  final markets = (pricing['markets'] as Map<String, dynamic>?) ?? const {};
  final normalizedBase = _normalizeUnitKey(baseUnit);
  final marketMap = _marketMapByKey(
    markets: markets,
    marketKey: salesMarketKey,
  );
  if (marketMap == null) return <MarketType, double>{};
  final prices = (marketMap['prices'] as Map<String, dynamic>?) ?? const {};
  final baseEntry = _findUnitPriceEntry(prices, normalizedBase);
  if (baseEntry == null) return <MarketType, double>{};
  final regular =
      (baseEntry['autoPriceQar'] as num?)?.toDouble() ??
      (baseEntry['manualPriceQar'] as num?)?.toDouble() ??
      0;
  if (regular <= 0) return <MarketType, double>{};
  return <MarketType, double>{selectedMarket: regular};
}

Map<MarketType, Map<String, double>> _readMarketUnitPrices(
  Map<String, dynamic> map, {
  required bool useOfferPrice,
  required String salesMarketKey,
  required MarketType selectedMarket,
}) {
  final pricing = (map['pricing'] as Map<String, dynamic>?) ?? const {};
  final markets = (pricing['markets'] as Map<String, dynamic>?) ?? const {};
  final marketMap = _marketMapByKey(
    markets: markets,
    marketKey: salesMarketKey,
  );
  if (marketMap == null) return <MarketType, Map<String, double>>{};
  final prices = (marketMap['prices'] as Map<String, dynamic>?) ?? const {};
  final unitMap = <String, double>{};
  for (final unitEntry in prices.entries) {
    if (unitEntry.value is! Map<String, dynamic>) continue;
    final unitData = unitEntry.value as Map<String, dynamic>;
    final rawUnit =
        (unitData['unit'] as String?) ??
        (unitData['key'] as String?) ??
        unitEntry.key;
    final unitKey = _normalizeUnitKey(rawUnit);
    final value = useOfferPrice
        ? (unitData['autoOfferPriceQar'] as num?)?.toDouble() ??
              (unitData['manualOfferPriceQar'] as num?)?.toDouble() ??
              0
        : (unitData['autoPriceQar'] as num?)?.toDouble() ??
              (unitData['manualPriceQar'] as num?)?.toDouble() ??
              0;
    if (value > 0) {
      unitMap[unitKey] = value;
    }
  }
  if (unitMap.isEmpty) return <MarketType, Map<String, double>>{};
  return <MarketType, Map<String, double>>{selectedMarket: unitMap};
}

Map<String, dynamic>? _marketMapByKey({
  required Map<String, dynamic> markets,
  required String marketKey,
}) {
  final normalizedTarget = marketKey.trim().toLowerCase();
  for (final entry in markets.entries) {
    if (entry.value is! Map<String, dynamic>) continue;
    if (entry.key.trim().toLowerCase() == normalizedTarget) {
      return entry.value as Map<String, dynamic>;
    }
  }
  return null;
}

Map<String, dynamic>? _findUnitPriceEntry(
  Map<String, dynamic> prices,
  String normalizedUnitKey,
) {
  for (final entry in prices.entries) {
    if (entry.value is! Map<String, dynamic>) continue;
    final item = entry.value as Map<String, dynamic>;
    final rawUnit =
        (item['unit'] as String?) ?? (item['key'] as String?) ?? entry.key;
    if (_normalizeUnitKey(rawUnit) == normalizedUnitKey) {
      return item;
    }
  }
  return null;
}

MarketType? _marketTypeFromKey(String key) {
  final normalized = key.trim().toLowerCase();
  if (normalized == 'hyper_market' || normalized == 'hyper') {
    return MarketType.hyper;
  }
  if (normalized == 'local_market' || normalized == 'local') {
    return MarketType.local;
  }
  return null;
}

String _normalizeUnitKey(String unit) => unit.trim().toLowerCase();
