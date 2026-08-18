import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/domain/repositories/products_repository.dart';

class GetProductsUseCase {
  final ProductsRepository _repository;

  const GetProductsUseCase(this._repository);

  Future<List<Product>> call({required String salesMarketKey}) {
    return _repository.getProducts(salesMarketKey: salesMarketKey);
  }

  Stream<List<Product>> watch({required String salesMarketKey}) {
    return _repository.watchProducts(salesMarketKey: salesMarketKey);
  }
}
