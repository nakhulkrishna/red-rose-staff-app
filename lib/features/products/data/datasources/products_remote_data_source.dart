import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_app/features/products/data/models/product_model.dart';

class ProductsRemoteDataSource {
  final FirebaseFirestore _firestore;

  const ProductsRemoteDataSource(this._firestore);

  Future<List<ProductModel>> getProducts({
    required String salesMarketKey,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('catalog_products')
          .where('status', isEqualTo: 'active')
          .orderBy('productNameLower')
          .get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      snapshot = await _firestore
          .collection('catalog_products')
          .where('status', isEqualTo: 'active')
          .get();
    }

    final products = snapshot.docs
        .map(
          (doc) => ProductModel.fromMap(
            doc.id,
            doc.data(),
            salesMarketKey: salesMarketKey,
          ),
        )
        .where((product) => product.hasMarketPriceConfigured)
        .toList();
    products.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return products;
  }
}
