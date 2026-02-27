import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';

final productsCatalogProvider = Provider<List<Product>>((ref) {
  return const [
    Product(
      id: 'P-100',
      code: 'RRS-APPLE',
      name: 'Fresh Apple',
      description: 'Premium red apples.',
      category: 'Fruits',
      imageUrl: '',
      baseUnit: 'KG',
      marketPrices: {
        MarketType.hyper: 4.0,
        MarketType.local: 4.5,
      },
      units: [
        ProductUnit(code: 'KG', multiplierToBase: 1, allowDecimal: true),
        ProductUnit(code: 'CTN', multiplierToBase: 10, allowDecimal: false),
        ProductUnit(code: 'Piece', multiplierToBase: 0.2, allowDecimal: false),
      ],
    ),
    Product(
      id: 'P-101',
      code: 'RRS-RICE',
      name: 'Basmati Rice',
      description: 'Long grain basmati rice.',
      category: 'Grains',
      imageUrl: '',
      baseUnit: 'KG',
      marketPrices: {
        MarketType.hyper: 2.5,
        MarketType.local: 2.9,
      },
      units: [
        ProductUnit(code: 'KG', multiplierToBase: 1, allowDecimal: true),
        ProductUnit(code: 'CTN', multiplierToBase: 25, allowDecimal: false),
        ProductUnit(code: 'Piece', multiplierToBase: 1, allowDecimal: false),
      ],
    ),
    Product(
      id: 'P-102',
      code: 'RRS-JUICE',
      name: 'Orange Juice',
      description: '100% fruit orange juice.',
      category: 'Beverages',
      imageUrl: '',
      baseUnit: 'Piece',
      marketPrices: {
        MarketType.hyper: 1.2,
        MarketType.local: 1.4,
      },
      units: [
        ProductUnit(code: 'Piece', multiplierToBase: 1, allowDecimal: false),
        ProductUnit(code: 'CTN', multiplierToBase: 12, allowDecimal: false),
      ],
    ),
  ];
});

final stockProvider = StateNotifierProvider<StockNotifier, Map<String, double>>((ref) {
  return StockNotifier();
});

class StockNotifier extends StateNotifier<Map<String, double>> {
  StockNotifier()
      : super(const {
          'P-100': 250,
          'P-101': 500,
          'P-102': 300,
        });

  void deductBaseUnits(Map<String, double> deductions) {
    final next = <String, double>{...state};
    for (final entry in deductions.entries) {
      final current = next[entry.key] ?? 0;
      next[entry.key] = (current - entry.value).clamp(0, double.infinity);
    }
    state = next;
  }
}
