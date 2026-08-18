import 'package:staff_app/features/orders/domain/entities/market_type.dart';
import 'package:staff_app/features/orders/domain/entities/product_unit.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';

/// Price of one [unit] of [product] in the salesman's [market].
///
/// Prefers an explicit per-unit market price and falls back to the market
/// base price scaled by the unit multiplier.
double resolveUnitPrice(Product product, MarketType market, ProductUnit unit) {
  final unitKey = unit.code.trim().toLowerCase();
  final marketUnitPrice = product.marketUnitPrices[market]?[unitKey];
  if (marketUnitPrice != null && marketUnitPrice > 0) {
    return marketUnitPrice;
  }
  final basePrice = product.marketPrices[market] ?? 0;
  return basePrice * unit.multiplierToBase;
}

/// Discounted price for one [unit], or null when no offer is configured.
double? resolveUnitOfferPrice(
  Product product,
  MarketType market,
  ProductUnit unit,
) {
  final unitKey = unit.code.trim().toLowerCase();
  final offer = product.marketUnitOfferPrices[market]?[unitKey];
  if (offer == null || offer <= 0) return null;
  final regular = resolveUnitPrice(product, market, unit);
  return offer < regular ? offer : null;
}

/// Images to show for a product, tolerating either field being empty.
List<String> productImages(Product product) {
  final urls = product.imageUrls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();
  if (urls.isNotEmpty) return urls;
  final single = product.imageUrl.trim();
  return single.isEmpty ? const [] : [single];
}
