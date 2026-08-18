import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/core/logging/app_logger.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

/// Firestore location of the shared order-WhatsApp setting.
const kAppConfigCollection = 'catalog_app_config';
const kOrderWhatsappDocId = 'order_whatsapp';

/// Legacy location written by the original admin app (world-readable).
const kLegacyWhatsappCollection = 'order_whatsapp';
const kLegacyWhatsappDocId = 'main_number';

/// WhatsApp number that order bills are sent to.
///
/// Read from `catalog_app_config/order_whatsapp` — a single shared setting
/// any signed-in user may read and only admins may write, configured from
/// the admin dashboard. Returns null when unset or unreadable.
final whatsappOrderNumberProvider = FutureProvider<String?>((ref) async {
  final firestore = ref.read(firestoreProvider);

  // 1) Shared catalog config (admin-writable only) — preferred source.
  try {
    final doc = await firestore
        .collection(kAppConfigCollection)
        .doc(kOrderWhatsappDocId)
        .get();
    final number = _readNumber(doc.data());
    if (number != null) return number;
  } on FirebaseException catch (e, st) {
    AppLogger.error(
      source: 'whatsappOrderNumberProvider/config',
      error: e,
      stackTrace: st,
    );
  }

  // 2) Legacy location written by the original admin app's settings screen.
  try {
    final doc = await firestore
        .collection(kLegacyWhatsappCollection)
        .doc(kLegacyWhatsappDocId)
        .get();
    final number = _readNumber(doc.data());
    if (number != null) return number;
  } on FirebaseException catch (e, st) {
    AppLogger.error(
      source: 'whatsappOrderNumberProvider/legacy',
      error: e,
      stackTrace: st,
    );
  }

  return null;
});

String? _readNumber(Map<String, dynamic>? data) {
  if (data == null) return null;
  final raw =
      ((data['number'] as String?) ??
              (data['whatsappOrderNumber'] as String?) ??
              '')
          .trim();
  return raw.isEmpty ? null : normalizeWhatsappNumber(raw);
}

/// Normalizes a stored number into the international form wa.me needs.
///
/// A stored `+` (or `00`) prefix is treated as authoritative. Bare local
/// numbers are given a country code by length: 8 digits -> Qatar (974),
/// 10 digits -> India (91).
String? normalizeWhatsappNumber(String raw) {
  final trimmed = raw.trim();
  final hadPlus = trimmed.startsWith('+') || trimmed.startsWith('00');
  var digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;

  if (trimmed.startsWith('00')) {
    digits = digits.substring(2);
  }
  if (hadPlus) return digits;

  if (digits.length == 8) return '974$digits';
  if (digits.length == 10) return '91$digits';
  return digits;
}
