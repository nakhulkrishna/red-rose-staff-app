import 'package:staff_app/products/provider/products_management.dart';

class SelectedOrder {
  final Product product;
  int quantity;

  String buyer;


  SelectedOrder({
    required this.product,
    required this.quantity,

    required this.buyer,
   
  });
}
