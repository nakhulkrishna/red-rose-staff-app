import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/products/data/datasources/products_remote_data_source.dart';
import 'package:staff_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/domain/usecases/get_products_usecase.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

final productsRemoteDataSourceProvider = Provider<ProductsRemoteDataSource>((
  ref,
) {
  return ProductsRemoteDataSource(ref.read(firestoreProvider));
});

final productsRepositoryProvider = Provider<ProductsRepositoryImpl>((ref) {
  return ProductsRepositoryImpl(ref.read(productsRemoteDataSourceProvider));
});

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.read(productsRepositoryProvider));
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final marketContext = await ref.watch(salesmanMarketContextProvider.future);
  return ref
      .read(getProductsUseCaseProvider)
      .call(salesMarketKey: marketContext.salesMarketKey);
});
