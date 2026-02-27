import 'package:staff_app/features/orders/domain/entities/market_type.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final MarketType marketType;
  final double outstandingBalance;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.marketType,
    required this.outstandingBalance,
  });
}
