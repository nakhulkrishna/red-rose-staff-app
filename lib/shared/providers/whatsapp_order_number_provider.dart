import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

/// WhatsApp number that order bills are sent to.
///
/// Configured from the admin dashboard (Settings -> WhatsApp Order Number),
/// stored as `whatsappOrderNumber` on the admin's `catalog_users` document.
/// Returns null when no admin has configured one.
final whatsappOrderNumberProvider = FutureProvider<String?>((ref) async {
  final firestore = ref.read(firestoreProvider);
  final snapshot = await firestore
      .collection('catalog_users')
      .where('whatsappOrderNumber', isNotEqualTo: '')
      .limit(10)
      .get();

  if (snapshot.docs.isEmpty) return null;

  String numberOf(Map<String, dynamic> data) =>
      (data['whatsappOrderNumber'] as String?)?.trim() ?? '';

  bool isAdmin(Map<String, dynamic> data) {
    final role = (data['role'] as String?)?.toLowerCase() ?? '';
    return role.contains('admin') || role.contains('manager');
  }

  // Prefer an admin's number; fall back to any configured one.
  final docs = snapshot.docs.where((doc) => numberOf(doc.data()).isNotEmpty);
  if (docs.isEmpty) return null;

  final adminDoc = docs.where((doc) => isAdmin(doc.data()));
  final chosen = adminDoc.isNotEmpty ? adminDoc.first : docs.first;

  return normalizeQatarWhatsappNumber(numberOf(chosen.data()));
});

/// Strips formatting and applies the Qatar country code to local numbers.
String? normalizeQatarWhatsappNumber(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  // Local 8-digit Qatari numbers need the 974 country code for wa.me links.
  if (digits.length == 8) {
    digits = '974$digits';
  }
  return digits;
}
