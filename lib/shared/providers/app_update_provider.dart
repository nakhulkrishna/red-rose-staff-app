import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:staff_app/core/logging/app_logger.dart';
import 'package:staff_app/shared/providers/firebase_providers.dart';

/// Firestore location of the force-update setting, editable from the
/// Firebase Console (or the admin dashboard):
///
/// catalog_app_config/app_version {
///   forceUpdate: true,          // master switch
///   minBuildNumber: 20,         // builds below this must update
///   latestVersion: '2.2.0',     // shown to the user
///   message: '...',             // optional custom text
///   androidUrl: 'https://play.google.com/store/apps/details?id=...',
///   iosUrl: 'https://apps.apple.com/app/id...',
/// }
const kAppVersionDocId = 'app_version';

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.updateRequired,
    this.latestVersion = '',
    this.message = '',
    this.androidUrl = '',
    this.iosUrl = '',
    this.currentVersion = '',
  });

  final bool updateRequired;
  final String latestVersion;
  final String message;
  final String androidUrl;
  final String iosUrl;
  final String currentVersion;

  static const none = AppUpdateStatus(updateRequired: false);
}

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Live so that flipping the flag in Firestore takes effect in running
/// apps without a restart. Any read failure fails open (no forced update).
final appUpdateStatusProvider = StreamProvider<AppUpdateStatus>((ref) async* {
  final firestore = ref.read(firestoreProvider);

  PackageInfo info;
  try {
    info = await ref.watch(packageInfoProvider.future);
  } catch (e, st) {
    AppLogger.error(source: 'appUpdateStatus/packageInfo', error: e, stackTrace: st);
    yield AppUpdateStatus.none;
    return;
  }
  final currentBuild = int.tryParse(info.buildNumber) ?? 0;

  yield* firestore
      .collection('catalog_app_config')
      .doc(kAppVersionDocId)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return AppUpdateStatus.none;

        final enabled = data['forceUpdate'] == true;
        final minBuild = _toInt(data['minBuildNumber']) ?? 0;
        if (!enabled || currentBuild >= minBuild) {
          return AppUpdateStatus.none;
        }

        return AppUpdateStatus(
          updateRequired: true,
          latestVersion: (data['latestVersion'] as String?)?.trim() ?? '',
          message: (data['message'] as String?)?.trim() ?? '',
          androidUrl: (data['androidUrl'] as String?)?.trim() ?? '',
          iosUrl: (data['iosUrl'] as String?)?.trim() ?? '',
          currentVersion: '${info.version}+${info.buildNumber}',
        );
      })
      .handleError((Object e, StackTrace st) {
        AppLogger.error(source: 'appUpdateStatus/config', error: e, stackTrace: st);
      });
});

int? _toInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
