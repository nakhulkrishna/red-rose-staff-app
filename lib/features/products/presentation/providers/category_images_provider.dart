import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

/// Category images managed from the admin panel, keyed by lowercased
/// category name. Missing docs or images simply fall back to a placeholder.
final categoryImagesProvider = StreamProvider<Map<String, String>>((ref) {
  final firestore = ref.read(firestoreProvider);
  return firestore.collection('catalog_product_categories').snapshots().map((
    snapshot,
  ) {
    final images = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] as String? ?? '').trim().toLowerCase();
      final imageUrl = (data['imageUrl'] as String? ?? '').trim();
      if (name.isEmpty || imageUrl.isEmpty) continue;
      images[name] = imageUrl;
    }
    return images;
  });
});
