import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/products/data/models/product_model.dart';
import 'package:staff_app/features/products/domain/entities/product_pricing.dart';

void main() {
  // Mirrors a real catalog_products document (auto-alay-16): numeric values
  // stored as strings, per-unit market pricing, manual override on KG.
  final map = <String, dynamic>{
    'productCode': '#AUTO-ALAY-16',
    'productName': 'Test Product',
    'status': 'active',
    'baseUnit': {'key': 'kg', 'name': 'KG'},
    'saleUnits': [
      {'conversionToBaseUnit': '1', 'name': 'KG', 'key': 'kg'},
      {'conversionToBaseUnit': '5', 'name': 'CTN', 'key': 'ctn'},
    ],
    'inventory': {'availableQtyBaseUnit': '20', 'baseUnitQty': '20'},
    'pricing': {
      'currency': 'QAR',
      'markets': {
        'hyper_market': {
          'prices': {
            'kg': {
              'unit': 'KG',
              'overrideEnabled': true,
              'manualPriceQar': '22',
              'manualOfferPriceQar': '20',
              'autoPriceQar': null,
              'autoOfferPriceQar': null,
            },
            'ctn': {
              'unit': 'CTN',
              'overrideEnabled': false,
              'manualPriceQar': null,
              'manualOfferPriceQar': null,
              'autoPriceQar': '110',
              'autoOfferPriceQar': '100',
            },
          },
        },
      },
    },
  };

  final product = ProductModel.fromMap(
    'auto-alay-16',
    map,
    salesMarketKey: 'hyper_market',
  );

  test('string-typed stock parses correctly', () {
    expect(product.availableStock, 20.0);
  });

  test('string-typed unit conversions parse correctly', () {
    final ctn = product.units.firstWhere((u) => u.code == 'CTN');
    final kg = product.units.firstWhere((u) => u.code == 'KG');
    expect(ctn.multiplierToBase, 5.0);
    expect(kg.multiplierToBase, 1.0);
  });

  test('decimals only on the base unit', () {
    final ctn = product.units.firstWhere((u) => u.code == 'CTN');
    final kg = product.units.firstWhere((u) => u.code == 'KG');
    expect(kg.allowDecimal, isTrue);
    expect(ctn.allowDecimal, isFalse);
  });

  test('manual price wins for KG, auto used for CTN', () {
    final kg = product.units.firstWhere((u) => u.code == 'KG');
    final ctn = product.units.firstWhere((u) => u.code == 'CTN');
    expect(resolveUnitPrice(product, MarketType.hyper, kg), 22.0);
    expect(resolveUnitOfferPrice(product, MarketType.hyper, kg), 20.0);
    expect(resolveUnitPrice(product, MarketType.hyper, ctn), 110.0);
    expect(resolveUnitOfferPrice(product, MarketType.hyper, ctn), 100.0);
  });

  test('order value: 2 CTN + 3 KG at offer prices', () {
    final kg = product.units.firstWhere((u) => u.code == 'KG');
    final ctn = product.units.firstWhere((u) => u.code == 'CTN');
    final kgApplied =
        resolveUnitOfferPrice(product, MarketType.hyper, kg) ??
        resolveUnitPrice(product, MarketType.hyper, kg);
    final ctnApplied =
        resolveUnitOfferPrice(product, MarketType.hyper, ctn) ??
        resolveUnitPrice(product, MarketType.hyper, ctn);
    // 2 CTN = 200 QAR, 3 KG = 60 QAR
    expect(2 * ctnApplied + 3 * kgApplied, 260.0);
    // stock consumed in base units: 2*5 + 3*1 = 13 KG of 20 available
    expect(2 * ctn.multiplierToBase + 3 * kg.multiplierToBase, 13.0);
  });

  test('market has price configured', () {
    expect(product.hasMarketPriceConfigured, isTrue);
    expect(product.marketPrices[MarketType.hyper], 22.0);
  });
}
