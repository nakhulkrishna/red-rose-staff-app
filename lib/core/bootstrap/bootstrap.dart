import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:staff_app/core/logging/app_logger.dart';
import 'package:staff_app/firebase_options.dart';

Future<void> bootstrap(FutureOr<void> Function() builder) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.error(
          source: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        AppLogger.error(
          source: 'PlatformDispatcher',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      // Keep image memory bounded on low-memory iOS devices.
      PaintingBinding.instance.imageCache
        ..maximumSize = 120
        ..maximumSizeBytes = 60 << 20;
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await builder();
    },
    (Object error, StackTrace stackTrace) {
      AppLogger.error(
        source: 'runZonedGuarded',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
