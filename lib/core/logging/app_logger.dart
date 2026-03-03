import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLogger {
  const AppLogger._();

  static void error({
    required String source,
    required Object error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '$source: $error',
      name: 'staff_app.error',
      error: error,
      stackTrace: stackTrace,
    );
    debugPrint('ERROR [$source] $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      source: 'Riverpod:${provider.name ?? provider.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
