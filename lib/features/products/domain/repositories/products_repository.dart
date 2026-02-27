import 'package:staff_app/features/products/domain/entities/product.dart';

abstract class ProductsRepository {
  Future<List<Product>> getProducts();
}
