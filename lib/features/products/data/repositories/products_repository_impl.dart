import 'package:staff_app/features/products/data/datasources/products_remote_data_source.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remoteDataSource;

  const ProductsRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Product>> getProducts() {
    return _remoteDataSource.getProducts();
  }
}
