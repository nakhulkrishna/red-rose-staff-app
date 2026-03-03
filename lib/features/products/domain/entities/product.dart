import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';

class Product {
  final String id;
  final String code;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final String baseUnit;
  final Map<MarketType, double> marketPrices;
  final Map<MarketType, Map<String, double>> marketUnitPrices;
  final Map<MarketType, Map<String, double>> marketUnitOfferPrices;
  final List<ProductUnit> units;
  final double priceQar;
  final double offerPriceQar;
  final double availableStock;
  final List<String> imageUrls;
  final bool hasMarketPriceConfigured;

  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.baseUnit,
    required this.marketPrices,
    this.marketUnitPrices = const {},
    this.marketUnitOfferPrices = const {},
    required this.units,
    this.priceQar = 0,
    this.offerPriceQar = 0,
    this.availableStock = 0,
    this.imageUrls = const [],
    this.hasMarketPriceConfigured = true,
  });
}
