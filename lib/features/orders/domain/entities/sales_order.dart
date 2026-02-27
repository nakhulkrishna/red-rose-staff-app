import 'package:staff_app/features/customers/domain/entities/customer.dart';
import 'package:staff_app/features/orders/domain/entities/cart_item.dart';

class SalesOrder {
  final String id;
  final DateTime createdAt;
  final Customer customer;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double grandTotal;

  const SalesOrder({
    required this.id,
    required this.createdAt,
    required this.customer,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
  });
}
